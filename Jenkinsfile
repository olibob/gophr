#!groovy

node {
  stage('checkout'){
    deleteDir()
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
      withCredentials([string(credentialsId: 'mailgunKey', variable: 'MAILGUN_KEY'), string(credentialsId: 'mailgunDomain', variable: 'MAILGUN_DOMAIN'), string(credentialsId: 'mailgunFrom', variable: 'MAILGUN_FROM'), string(credentialsId: 'mailgunTo', variable: 'MAILGUN_TO')]) {
        sh "curl -s --user \"api:$MAILGUN_KEY\" https://api.mailgun.net/v3/$MAILGUN_DOMAIN/messages -F from=\"Jenkins <$MAILGUN_FROM>\" -F to=\"$MAILGUN_TO\" -F subject=\"Job ${env.JOB_NAME} [${env.BUILD_NUMBER}] failed\" -F text=\"${env.BUILD_URL}\""
    }
      throw err
    }
    finally {
      junit 'testOutput.xml'
    }
  }

  stage('Artifact') {
    docker.build('gophr')
    docker.withRegistry("https://151246526130.dkr.ecr.eu-central-1.amazonaws.com", "ecr:eu-central-1:awsID") {
      docker.image("gophr").push("${env.BUILD_NUMBER}")
    }
  }

  stage('Deploy') {
    sh 'deployDev.sh'
  }
}
