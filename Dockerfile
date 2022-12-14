ARG BASE_CONTAINER=jupyter/minimal-notebook:python-3.7

FROM $BASE_CONTAINER

ARG SPARK_VERSION=2.4.7

ENV SPARK_VER $SPARK_VERSION
ENV SPARK_HOME /opt/spark


RUN conda install --quiet --yes \
    cffi \
    send2trash \
    requests \
    future \
    pycryptodomex && \
    conda clean --all && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER root

RUN apt update && apt install -yq curl openjdk-8-jdk

ENV JAVA_HOME /usr/lib/jvm/java
RUN ln -s $(readlink -f /usr/bin/javac | sed "s:/bin/javac::") ${JAVA_HOME}

# Download and install Spark
RUN curl -s https://archive.apache.org/dist/spark/spark-${SPARK_VER}/spark-${SPARK_VER}-bin-without-hadoop.tgz | \
    tar -xz -C /opt && \
    ln -s ${SPARK_HOME}-${SPARK_VER}-bin-without-hadoop $SPARK_HOME && \
    mkdir -p /usr/hdp/current/ && \
    ln -s ${SPARK_HOME}-${SPARK_VER}-bin-without-hadoop /usr/hdp/current/spark2-client

# Install Enterprise Gateway wheel and kernelspecs
COPY jupyter_enterprise_gateway*.whl /tmp/
RUN pip install /tmp/jupyter_enterprise_gateway*.whl && \
	rm -f /tmp/jupyter_enterprise_gateway*.whl

ADD jupyter_enterprise_gateway_kernelspecs*.tar.gz /usr/local/share/jupyter/kernels/
ADD jupyter_enterprise_gateway_kernel_image_files*.tar.gz /usr/local/bin/

COPY start-enterprise-gateway.sh /usr/local/bin/

RUN chown jovyan:users /usr/local/bin/start-enterprise-gateway.sh && \
	chmod 0755 /usr/local/bin/start-enterprise-gateway.sh && \
	touch /usr/local/share/jupyter/enterprise-gateway.log && \
	chown -R jovyan:users /usr/local/share/jupyter /usr/local/bin/kernel-launchers && \
	chmod 0666 /usr/local/share/jupyter/enterprise-gateway.log && \
	rm -f /usr/local/bin/bootstrap-kernel.sh && \
    pip3 install pyspark

RUN mkdir -p /opt/spark/jars/
COPY jersey-bundle-1.17.1.jar /opt/spark/jars/jersey-bundle-1.17.1.jar

USER jovyan

CMD ["/usr/local/bin/start-enterprise-gateway.sh"]

EXPOSE 8888

WORKDIR /usr/local/bin

