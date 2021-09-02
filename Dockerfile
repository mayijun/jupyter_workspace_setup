FROM ubuntu:focal
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
    wget --no-check-certificate --quiet https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-latest-Linux-x86_64.sh

COPY .condarc /root/.condarc

RUN $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy

# add conda tsinghua mirror to speed up in CN

# below part  referred docker-stacks/base-notebooks

RUN curl --insecure https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl --insecure https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && echo 'Acquire::https::Verify-Peer "false";'> /etc/apt/apt.conf.d/apt.conf \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools unixodbc unixodbc-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install sql server odbc. curl use --insecure option as my company use self-managed PKI. so ingore the CA issue

#install nodejs as jupyterlab extention required

ARG PIPOPTION
ARG PYTHON

RUN conda install python=$PYTHON  && conda clean -y -a

# install db related python package and basic packages

RUN pip install  ${PIPOPTION}  \
    psycopg2-binary \
    pyodbc \
    sqlalchemy \
    xlsxwriter \
    openpyxl \
	xlrd \
	python-dateutil \
	python-pptx \
	pymysql \
    && rm -rf /tmp/pip-*-unpack

# ipython backend layer packages: used for modeling and computing
ARG IPYTHON
ARG PANDAS
ARG JUPYTERLAB
ARG NUMPY
ARG NUMBA
ARG XEUS_PYTHON

RUN pip install ${PIPOPTION}\
    xgboost \
    ipython==$IPYTHON \
    numpy==$NUMPY \
    numba==$NUMBA \
    pandas==$PANDAS \
    jupyterlab==$JUPYTERLAB \
    voila \
    xeus-python \
    scikit-learn \
    jupyterlab-language-pack-zh-CN \
    jupyterlab-git \
    && rm -rf /tmp/pip-*-unpack


# frond end packages: used for graphing and charts

ARG PLOTLY
ARG IPYWIDGETS

RUN  pip install  ${PIPOPTION}  \
     plotly-express \
     ipympl \
     pyecharts \
     plotly==$PLOTLY \
     kaleido \
     jupyter_bokeh \
     jupyter-dash \
     ipywidgets==$IPYWIDGETS \
     seaborn \
     && rm -rf /tmp/pip-*-unpack

#basic package setup, some packages's version are not defined as they are not stable yet and clean up caches

RUN  mkdir -p /root/report

# folder to hold all notebooks

WORKDIR /root

COPY jupyter_notebook_config.py /root/.jupyter/
COPY start_notebook.sh /root/

RUN chmod +x /root/start_notebook.sh

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["/root/start_notebook.sh"]
