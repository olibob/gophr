#!groovy

node {
  stage('checkout'){
    git branch: 'dev', url: 'https://github.com/olibob/gophr.git'
  }

  stage('Build') {
    sh 'docker run --rm -v "$PWD":/usr/src/gophr -w /usr/src/gophr builder  go build -v'
  }

  stage('Test') {
    try {
      sh 'docker run --rm -v "$PWD":/usr/src/gophr -w /usr/src/gophr builder sh -c "go test -v | go2xunit -fail" > testOutput.xml'
    } catch(err) {
      slackSend color: 'danger', message: "Job ${env.JOB_NAME} [${env.BUILD_NUMBER}] failed (${env.BUILD_URL})"
      throw err
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
