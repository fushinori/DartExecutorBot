FROM google/dart
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    neofetch

WORKDIR /app

COPY pubspec.* /app/
RUN pub get
COPY . /app
RUN pub get --offline

CMD []
ENTRYPOINT ["/usr/bin/dart", "main.dart"]
