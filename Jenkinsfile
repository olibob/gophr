#!groovy

node {
    stage('Checkout') {
      deleteDir()
      git 'https://github.com/olibob/gotest.git'
    }

    stage('Build') {
            sh 'docker run --rm -v "$PWD":/usr/src/gophr -w /usr/src/gophr builder  go build -v'
    }

    stage('Test') {
        try {
            sh 'docker run --rm -v "$PWD":/usr/src/gophr -w /usr/src/gophr builder sh -c "go test -v | go2xunit -fail" > testOutput.xml'
        }
        finally {
            junit 'testOutput.xml'
        }
    }

    stage('Deploy') {
        if (currentBuild.result == 'SUCCESS') {
            echo 'Deployed'
        }
    }
}