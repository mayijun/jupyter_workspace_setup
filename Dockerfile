FROM ubuntu:bionic
# switch from anaconda python3 image to ubuntu clean image, as debian 8 do not support sql
# server odbc driver well

MAINTAINER Simon MA <ma.yijun@outlook.com>

USER root

#  below part refered docker-stacks/base-notebooks

ENV DEBIAN_FRONTEND noninteractive

#add ubuntu cn mirror to speed up
#COPY sources.list /etc/apt/sources.list
#RUN chown root:root /etc/apt/sources.list && chmod 644 /etc/apt/sources.list

RUN apt-get update  \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    apt-transport-https \
    git \
    gnupg \
    tzdata \
    build-essential \
    fonts-dejavu \
    gfortran \
    libcairo2-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install Tini
RUN apt-get update  && apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean \
     && rm -rf /var/lib/apt/lists/*

ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

ENV PATH=$CONDA_DIR/bin:$PATH

RUN cd /tmp && \
    wget --no-check-certificate --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    conda config --set show_channel_urls yes && \
    conda config --add channels conda-forge &&\
    conda config --set ssl_verify false &&\
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy

# add conda tsinghua mirror to speed up in CN

# below part  referred docker-stacks/base-notebooks

RUN curl --insecure https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl --insecure https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && echo 'Acquire::https::Verify-Peer "false";'> /etc/apt/apt.conf.d/apt.conf \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools libssl1.0.0 unixodbc unixodbc-dev \
    && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

# install sql server odbc. curl use --insecure option as my company use self-managed PKI. so ingore the CA issue

#install nodejs as jupyterlab extention required

ARG NODEJS
ARG PYTHON

RUN conda install python=$PYTHON  && conda clean -y -a

RUN conda install -c conda-forge -y nodejs=$NODEJS && conda clean -y -a


# install db related python package and basic packages
ARG PYODBC
ARG LIBGCC
ARG PSYCOPG2


RUN pip install  --trusted-host pypi.tuna.tsinghua.edu.cn -i https://pypi.tuna.tsinghua.edu.cn/simple  \
    psycopg2-binary==$PSYCOPG2 \
    pyodbc==$PYODBC \
    xlsxwriter \
	xlrd \
	python-dateutil \
    && rm -rf /tmp/pip-*-unpack

# ipython backend layer packages: used for modeling and computing
ARG IPYTHON
ARG IPYTHON_SQL
ARG XGBOOST
ARG PANDAS
ARG SCIKIT_LEARN
ARG JUPYTERLAB
ARG NOTEBOOK
ARG NUMPY
ARG NUMBA
ARG XEUS_PYTHON

RUN pip install --trusted-host pypi.tuna.tsinghua.edu.cn -i https://pypi.tuna.tsinghua.edu.cn/simple \
    xgboost==$XGBOOST \
    && rm -rf /tmp/pip-*-unpack \
    &&  conda install -c conda-forge -y ipython=$IPYTHON \
        pandas=$PANDAS \
        numpy=$NUMPY \
        numba=$NUMBA \
        scikit-learn=$SCIKIT_LEARN \
        jupyterlab=$JUPYTERLAB \
        notebook=$NOTEBOOK \
        xeus-python=$XEUS_PYTHON \
        ptvsd \
    && conda clean -y -a

ARG R_ESSENTIAL

RUN conda install  --yes -c r r-essentials=$R_ESSENTIAL && \
    conda clean -y -a

# frond end packages: used for graphing and charts

ARG PYECHARTS
ARG PLOTLY
ARG CUFFLINKS
ARG IPYWIDGETS
ARG SEABORN
ARG JUPY_NBEXT

RUN  pip install  --trusted-host pypi.tuna.tsinghua.edu.cn -i https://pypi.tuna.tsinghua.edu.cn/simple   \
     plotly-express \
     ipympl \
     pyecharts==$PYECHARTS \
     plotly==$PLOTLY \
    && conda install -y \
    ipywidgets=$IPYWIDGETS \
     seaborn=$SEABORN \
     && rm -rf /tmp/pip-*-unpack \
     && conda clean -y -a
#basic package setup, some packages's version are not defined as they are not stable yet and clean up caches

# Avoid "JavaScript heap out of memory" errors during extension installation
# (OS X/Linux)
ENV NODE_OPTIONS="--max-old-space-size=4096"

ARG LAB_MANAGER

RUN node /opt/conda/lib/python3.7/site-packages/jupyterlab/staging/yarn.js config set "strict-ssl" false

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@$LAB_MANAGER

RUN jupyter labextension install @bokeh/jupyter_bokeh && \
#    jupyter labextension install @jupyterlab/dataregistry-extension && \
    jupyter labextension install @jupyterlab/debugger

RUN jupyter labextension install jupyterlab-plotly && \
    jupyter labextension install plotlywidget

RUN jupyter labextension install @jupyterlab/git && \
    pip install --upgrade jupyterlab-git && rm -rf /tmp/pip-*-unpack  && \
    jupyter serverextension enable --py jupyterlab_git

RUN  mkdir -p /root/report

# folder to hold all notebooks

WORKDIR /root

COPY jupyter_notebook_config.py /root/.jupyter/
COPY start_notebook.sh /root/

RUN chmod +x /root/start_notebook.sh

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["/root/start_notebook.sh"]
