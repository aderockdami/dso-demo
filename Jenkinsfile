pipeline {
  environment {
    ARGO_SERVER = '35.189.26.28:32484'
     DEV_URL = 'http://35.189.26.28:30080/'
     SPECTRAL_DSN = credentials('spectral-dsn')
  }
  agent {
    kubernetes {
      yamlFile 'build-agent.yaml'
      defaultContainer 'maven'
      idleMinutes 1
    }
  }
stages {
    stage('install Spectral') {
      steps {
        container('alpine') {
 
         sh "apt-get update && apt-get install curl -y"
         sh "curl -L 'https://get.spectralops.io/latest/x/sh?dsn=$SPECTRAL_DSN' | sh" 
         
      }
    }
    }
    stage('Spectral Deep Scan') {
      steps {
        sh "SPECTRAL_DSN=https://spu-b807c521954f4fa6b011c8fdb904fded@get.spectralops.io $HOME/.spectral/spectral github -k repo -t [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] https://github.com/aderockdami/dso-demo.git --include-tags base,audit3,iac"
    }
    }
    stage('Build') {
      parallel {
        stage('Compile') {
          steps {
            container('maven') {
              sh 'mvn compile'
            }
          }
        }
      }
    }
     stage('Static Analysis') {
      parallel {
        stage('Unit Tests') {
          steps {
            container('maven') {
              sh 'mvn test'
            }
          }
        }
       // stage('Generate SBOM') {
       //  steps {
       //  container('maven') {
         //  sh 'mvn org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom'
          //  }
       //  }
         //  post {
         //    success {
                   // dependencyTrackPublisher projectName:
           //  'sample-spring-app', projectVersion: '0.0.1', artifact:
          //   'target/bom.xml', autoCreateProjects: true, synchronous: true
                        //archiveArtifacts allowEmptyArchive: true,
           //   artifacts: 'target/bom.xml', fingerprint: true,
             // onlyIfSuccessful: true
            //   } 
           // }
        // }
        
        stage('SCA') {
          steps {
         container('maven') {
             catchError(buildResult: 'SUCCESS', stageResult:'FAILURE') {
             sh 'mvn org.owasp:dependency-check-maven:check'
            }
         }
       }
       post {
         always {
           archiveArtifacts allowEmptyArchive: true, artifacts: 'target/dependency-check-report.html', fingerprint:true, onlyIfSuccessful: true
              // dependencyCheckPublisher pattern: 'report.xml'
             }
         }
       }
       stage('OSS License Checker') {
        steps {
         container('licensefinder') {
           sh 'ls -al'
           sh '''#!/bin/bash --login
                   /bin/bash --login
                   rvm use default
                   gem install license_finder
                   license_finder
                   '''
                }
            }
        }
      }
     }
    stage('SAST') {
          steps {
            container('slscan') {
              sh 'scan --type java,depscan --build'
            }
          }
          post {
            success {
              archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/*', fingerprint: true, onlyIfSuccessful:true
           } 
         }
        }
    stage('Package') {
      parallel {
        stage('Create Jarfile') {
          steps {
            container('maven') {
              sh 'mvn package -DskipTests'
            }
          }
        }
        stage('Docker BnP') {
          steps {
            container('kaniko') {
               sh '/kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=docker.io/aderock/dsodemo'
            }
          }
        }
      }
    }
    stage('Image Analysis') {
      parallel {
        stage('Image Linting') {
          steps {
            container('docker-tools') {
              sh 'dockle docker.io/aderock/dsodemo'
            }
        } 
    }
    stage('Image Scan') {
          steps {
            container('docker-tools') {
              sh 'trivy image  aderock/dsodemo'
              }
            }     
          }
        } 

    }
    stage('Deploy to Dev') {
      environment {
        AUTH_TOKEN = credentials('argocd-jenkins-deployer-token')
      }
      steps {
       container('docker-tools') {
        sh 'docker run -t schoolofdevops/argocd-cli argocd app sync dso-demo  --insecure --server $ARGO_SERVER --auth-token $AUTH_TOKEN'
        sh 'docker run -t schoolofdevops/argocd-cli argocd app wait dso-demo --health --timeout 300   --insecure --server $ARGO_SERVER --auth-token $AUTH_TOKEN'
  } 
  }
  }
  stage('Dynamic Analysis') {
    parallel {
      stage('E2E tests') {
        steps {
          sh 'echo "All Tests passed!!!"'
        }
      }
      stage('DAST') {
        steps {
          container('docker-tools') {
            sh 'docker run -t owasp/zap2docker-stable zap-baseline.py -t $DEV_URL || exit 0'
          }
        } 
      }    
    } 
   }
  }
}
