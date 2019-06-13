FROM ubuntu:xenial
# switch from anaconda python3 image to ubuntu clean image, as debian 8 do not support sql
# server odbc driver well

MAINTAINER Simon MA <ma.yijun@outlook.com>

USER root

#  below part refered docker-stacks/base-notebooks

ENV DEBIAN_FRONTEND noninteractive

#add ubuntu cn mirror to speed up
COPY sources.list /etc/apt/sources.list
RUN chown root:root /etc/apt/sources.list && chmod 644 /etc/apt/sources.list

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
    tzdata \
    gcc \
    g++ \
    fonts-dejavu \
    gfortran \
    libcairo2-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

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

ARG MINICONDA_VERSION
RUN cd /tmp && \
    wget --quiet https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
    conda config --set show_channel_urls yes && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/ &&\
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy

# add conda tsinghua mirror to speed up in CN

# below part  referred docker-stacks/base-notebooks

RUN curl --insecure https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl --insecure https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && echo 'Acquire::https::Verify-Peer "false";'> /etc/apt/apt.conf.d/apt.conf \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql unixodbc unixodbc-dev \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools \
    && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

# install sql server odbc. curl use --insecure option as my company use self-managed PKI. so ingore the CA issue

#install nodejs as jupyterlab extention required

ARG NODEJS

RUN conda install -y nodejs=$NODEJS && conda clean -y -a


# install db related python package
ARG PYODBC
ARG LIBGCC
ARG PSYCOPG2


RUN conda install -y pyodbc=$PYODBC \
        libgcc=$LIBGCC \
	psycopg2=$PSYCOPG2 \
	xlsxwriter \
    && conda clean -y -a 

# ipython backend layer packages: used for modeling and computing
ARG IPYTHON
ARG IPYTHON_SQL
ARG XGBOOST
ARG PANDAS
ARG SCIKIT_LEARN
ARG JUPYTERLAB
ARG NOTEBOOK

RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
    ipython-sql==$IPYTHON_SQL \
    xgboost==$XGBOOST \
    && rm -rf /tmp/pip-*-unpack \
    &&  conda install -y ipython=$IPYTHON \
        pandas=$PANDAS \
        scikit-learn=$SCIKIT_LEARN \
        jupyterlab=$JUPYTERLAB \
        notebook=$NOTEBOOK \
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

RUN  pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
     plotly-express \
     pyecharts==$PYECHARTS \
     cufflinks==$CUFFLINKS \
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

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

RUN jupyter labextension install jupyterlab_bokeh && \
    jupyter labextension install jupyter-matplotlib

RUN jupyter labextension install @jupyterlab/plotly-extension && \
    jupyter labextension install plotlywidget && \
    jupyter labextension install jupyterlab-chart-editor

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
