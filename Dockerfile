FROM resin/armv7hf-debian
LABEL maintainer="outposter@gmail.com"

# Required ystem packages and cleanup
RUN  apt-get update \
    && apt-get install -y curl wget \
	tesseract-ocr \
	libtesseract-dev \
	bzip2 tar unzip \
	ca-certificates \
	libglib2.0-0 libxext6 libsm6 libxrender1 \
	&& apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Custom user to so we don't run under root
RUN useradd -ms /bin/bash apiuser

# Getting the latest miniconda installer and make the user owner
# ADD http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-armv7l.sh /home/apiuser/miniconda.sh


# Switch to apiuser
USER apiuser
WORKDIR /home/apiuser
RUN mkdir /home/apiuser/.conda
RUN mkdir /home/apiuser/app
RUN mkdir /home/apiuser/app/cache

# Install miniconda

# RUN /bin/bash /home/apiuser/miniconda.sh -b -p /home/apiuser/miniconda3
# ENV PATH=/home/apiuser/miniconda3/bin:${PATH}
# RUN conda update -y conda

RUN curl -s -L https://github.com/jjhelmus/berryconda/releases/download/v2.0.0/Berryconda3-2.0.0-Linux-armv7l.sh > miniconda.sh && \
    chown apiuser /home/apiuser/miniconda.sh && \
    # openssl md5 miniconda.sh | grep a01cbe45755d576c2bb9833859cf9fd7 && \
    bash miniconda.sh -b -p /home/apiuser/miniconda3 && \
    rm miniconda.sh
    
# RUN chown apiuser /home/apiuser/miniconda.sh

RUN export PATH="/home/apiuser/miniconda3/bin:${PATH}" && \
    conda config --set show_channel_urls True && \
		conda config --add channels rpi && \
    conda update --all --yes && \
		conda install -y python=3.6 -c rpi && \
    conda install conda-build && \
    conda install anaconda-client && \
		conda clean -tipsy

ENV PATH /home/apiuser/miniconda3/bin:$PATH


# Install the conda packages
RUN conda config --add channels conda-forge
RUN conda install --yes \
    fastapi \
    uvicorn \
    pip

# Install the pip packages
RUN pip install \
    requests \
    requests[socks] \
    requests[security] \
    fake_headers \
    tesseract \
    pytesseract \
    Pillow

# Copy the python files to the image
COPY ./app/api.py /home/apiuser/app/api.py
COPY ./app/gas_prices.py /home/apiuser/app/gas_prices.py
WORKDIR /home/apiuser/app

# Expose 5035 port for API
EXPOSE 5035

# Run fastapi with the app (api.py)
CMD ["/bin/bash", "-c", "uvicorn --proxy-headers api:app --host=0.0.0.0 --port=5035"]
