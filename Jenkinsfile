node {
  stage('Build') {
    sh 'docker run --rm -v "$PWD":/usr/src/gophr -w /usr/src/gophr golang:1.7.5-alpine3.5  go build -v'
  }
}
