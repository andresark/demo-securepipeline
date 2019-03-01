pipeline {
  agent any
  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/halzn/demo-securepipeline.git'
      }
    }
    stage('Docker build - creating a Container Image') {
      steps {
        script {
          docker.build('smartcheck-registry')
        }

      }
    }
    stage('ECR push - Pushing this image to a Container Registry') {
      steps {
        script {
          docker.withRegistry('https://906668750117.dkr.ecr.us-east-1.amazonaws.com', 'ecr:us-east-1:jenkins-user') {
            docker.image('smartcheck-registry').push(env.IMAGETAG+'-'+env.BUILD_ID)}
          }

        }
      }
      stage('Smartcheck - Scanning the Container Image in the Container Registry for Vulnerabilities, Secrets, and Malware') {
        steps {
          script {
            withCredentials([usernamePassword(credentialsId: 'smartcheck-credentials',
            usernameVariable: 'USER', passwordVariable: 'PASSWORD')]) {
              def NAME = env.IMAGETAG+'-'+env.BUILD_ID
              $FLAG = sh([ script: 'python /home/scAPI.py', returnStdout: true ]).trim()
              if ($FLAG == '1') {sh 'docker tag smartcheck-registry sc-blessed'
              docker.withRegistry('https://906668750117.dkr.ecr.us-east-1.amazonaws.com', 'ecr:us-east-1:jenkins-user') {
                docker.image('blessed').push(NAME) }
              } else {
                sh 'docker tag smartcheck-registry sc-quarantined'
                docker.withRegistry('https://906668750117.dkr.ecr.us-east-1.amazonaws.com', 'ecr:us-east-1:jenkins-user') {
                  docker.image('sc-quarantined').push(NAME) }
                  sh 'exit 1'
                }
              }
            }

          }
        }
        stage('Deploy') {
          steps {
            script {
              env.PATH = "/usr/bin:/usr/local/bin:/home/bin:/home/ec2-user:${env.PATH}"
              env.KUBECONFIG = "/home/.kube/config"
              sh 'aws eks update-kubeconfig --name eks-deploy'
              def NAME = env.IMAGETAG+'-'+env.BUILD_ID

              try {
                sh returnStdout: true, script: "/usr/local/bin/helm install --name=newmyapp /home/myapp --set image.repository=${REPOSITORY} --set image.tag=${NAME}"
              }
              catch (exc) {
                sh returnStdout: true, script: "helm upgrade --wait --recreate-pods newmyapp /home/myapp --set image.repository=${REPOSITORY} --set image.tag=${NAME}"
              }
            }

          }
        }
      }
      environment {
        IMAGETAG = 'tomcat'
        HIGH = '1'
        MEDIUM = '5'
        LOW = '5'
        NEGLIGIBLE = '5'
        UNKNOWN = '5'
        REPOSITORY = '906668750117.dkr.ecr.us-east-1.amazonaws.com/blessed'
        KUBECONFIG = '/home/.kube/config'
        NAMESPACE = 'default'
      }
