FROM basho/riak-kv
COPY ./etc/riak.conf /etc/riak.conf
RUN sed -i "s|search = off|search = on|g" /etc/riak.conf
