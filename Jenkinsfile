pipeline {
   agent any
   environment {
        PROJECT_ID = 'aesthetic-genre-277613'
        CLUSTER_NAME = 'model-service-cluster'
        LOCATION = 'us-central1-c'
        CREDENTIALS_ID = 'aesthetic-genre-277613'
        POST_BUILD_URL = 'https://7a44b00944e0.ngrok.io/api/v1/event/'
        DOCKERHUB_USER = 'unni123123'
        DOCKERHUB_REPO = 'model-service-image-repo'
        CONTAINER_NAME = 'model-service-container'
        STAGE_BEGIN_MESSAGE = ''
        STAGE_SUCCESS_MESSAGE = ''
        STAGE_FAILURE_MESSAGE = ''
        
    }
   stages {
      stage('Download Model from Cloud Storage') {
         steps {
			 script {
				env.LATEST_MODEL_USECASE_ID=env.OBJECT_NAME.minus(".zip")
			 }
            downloadModelFromCloud()
            notifyPipelineBeginning()
         }
      }
      stage('Setup Applications') {
         steps {
            setup()
         }
      }
      stage('Checkout Model Service Repo') {
         steps {
            sh label: '', script: '''
            mkdir -p ModelService'''
            dir('ModelService') {
                git credentialsId: 'krmenon431', url: 'https://github.com/krmenon431/ModelServiceProd.git'
            }
         }
      }
      stage('Add Model to Source Code') {
         steps {
            addModelToSourceCode()
         }
      }
      stage('Build Docker Image') {
         steps {
             script {
                 STAGE_BEGIN_MESSAGE = "Started Building Docker Image"
             }
             notifyStageBeginStatus(env.STAGE_NAME, STAGE_BEGIN_MESSAGE)
             script {
                 STAGE_SUCCESS_MESSAGE = "Docker Image Built Successfully"
                 try {
                    buildDockerImage()
                    notifyStageSuccessStatus (env.STAGE_NAME, STAGE_SUCCESS_MESSAGE)
                 }
                 catch (Exception e) {
                    STAGE_FAILURE_MESSAGE = "Docker Image Built Unsuccessfully"
                    notifyStageFailureStatus (env.STAGE_NAME, STAGE_FAILURE_MESSAGE)
                    throw e
                 }
             }
         }
      }
      stage('Push Docker Image to Docker Registry') {
         steps {
             script {
                 STAGE_BEGIN_MESSAGE = "Started Pushing Docker Image To DockerHub"
             }
             notifyStageBeginStatus(env.STAGE_NAME, STAGE_BEGIN_MESSAGE)
             script {
                 try {
                     STAGE_SUCCESS_MESSAGE = "Pushing Docker Image To DockerHub Successful"
                    pushDockerImageToDockerHub()
                    notifyStageSuccessStatus (env.STAGE_NAME, STAGE_SUCCESS_MESSAGE)
                 }
                 catch (Exception e) {
                     STAGE_FAILURE_MESSAGE = "Pushing Docker Image To DockerHub Unsuccessful"
                    notifyStageFailureStatus (env.STAGE_NAME, STAGE_FAILURE_MESSAGE)
                    throw e
                 }
             }
         }
      }
      stage('Deploy to Kubernetes') {
          steps{
              script {
                  STAGE_BEGIN_MESSAGE = "Started Deployment Of Docker Image To Kubernetes"
              }
              notifyStageBeginStatus(env.STAGE_NAME, STAGE_BEGIN_MESSAGE)
            script {
                 try {
                    STAGE_SUCCESS_MESSAGE = "Deployment Of Docker Image To Kubernetes Successful"
                    deployContainerInGKE()
                    notifyStageSuccessStatus (env.STAGE_NAME, STAGE_SUCCESS_MESSAGE)
                 }
                 catch (Exception e) {
                     STAGE_FAILURE_MESSAGE = "Deployment Of Docker Image To Kubernetes Unsuccessful"
                    notifyStageFailureStatus (env.STAGE_NAME, STAGE_FAILURE_MESSAGE)
                    throw e
                 }
            }
          }
      }
   }
   post {
        success {
            executeOnBuildSuccess()
        }
        failure {
            executeOnBuildFailure()
        }
    }
}

def downloadModelFromCloud () {
    sh label: '', script: '''
        sudo rm -rf historymodel
        mkdir -p historymodel
        sudo rm -rf latestmodel
        mkdir -p latestmodel
        sudo apt install -y unzip'''
    withAWS(credentials: 'aws-devops', region: 'us-east-2') {
        sh label: '', script: '''
            latestModelName=${OBJECT_NAME}
            if [ -z "$latestModelName" ]; then
               echo "No Models Found in latest Bucket"
            else
                latestModelStatus=(`aws s3api head-object --bucket latest-model --output text --query 'Metadata.status' --key $latestModelName`)
            fi
            if [ $latestModelStatus == "active" ]
            then
                echo "model to be downloaded"
                sudo aws s3 cp s3://latest-model/${latestModelName} ./latestmodel
            fi
            historyModelNames=(`aws s3 ls  history-model --recursive | sort | awk '{print $4}'`)
            a=0
            while [ $a -lt ${#historyModelNames[@]} ]
            do
               echo $a
               historyModelStatus=(`aws s3api head-object --bucket history-model --output text --query 'Metadata.status' --key ${historyModelNames[$a]}`)
               echo $historyModelStatus
               if [ $historyModelStatus == "active" ]
               then
                  echo "model to be downloaded"
                  sudo aws s3 cp s3://history-model/${historyModelNames[$a]} ./historymodel
               fi
               a=`expr $a + 1`
            done
            '''
    }
    dir('historymodel') {
        script {
            try {
                sh label: '', script: '''
                sudo unzip -o \'*.zip\'
                sudo rm *.zip
                sudo chmod -R a+rwx *'''
            }
            catch(Exception e) {
                echo "No Models Found in History Bucket"
            }
        }
    }
    dir('latestmodel') {
        script {
            try {
                sh label: '', script: '''
                sudo unzip -o \'*.zip\'
                sudo rm *.zip
                sudo chmod -R a+rwx *'''
            }
            catch(Exception e) {
                echo "No Models Found in Latest Bucket"
            }
            sh "ls --ignore='foldername' > foldername";
                def model_name=readFile('foldername').trim()
                if (model_name != null) { 
                 env.LATEST_MODEL_NAME = model_name
                } else { 
                 env.LATEST_MODEL_NAME = ''
                }
                sh "sudo rm foldername"
                echo "LATEST_MODEL_NAME=${env.LATEST_MODEL_NAME}";
        }
    }
}

def setup() {
    sh label: '', script: '''
        sudo apt-get remove docker docker-engine docker.io containerd runc
        sudo apt-get update
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository \
           "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) \
           stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo docker run hello-world
        '''
}

def addModelToSourceCode () {
    sh label: '', script: '''
    sudo rm -rf ModelService/modelfiles/usecases
    sudo mkdir -p ModelService/modelfiles/usecases
    sudo rm -rf ModelService/modelfiles/usecases/classifiers
    sudo mkdir -p ModelService/modelfiles/usecases/classifiers
    if [ -z "$(ls -A historymodel)" ]; then
       echo "historymodel is Empty"
    else
        sudo cp -avr -f -n ./historymodel/*/*.model ./ModelService/modelfiles/usecases/classifiers
        sudo rm -rf ./historymodel/*/*.model
        sudo cp -avr -f ./historymodel/* ./ModelService/modelfiles/usecases/
        sudo rm -rf ./historymodel/*
    fi
    if [ -z "$(ls -A latestmodel)" ]; then
       echo "latestmodel is Empty"
    else
        sudo cp -avr -f -n ./latestmodel/*/*.model ./ModelService/modelfiles/usecases/classifiers/
        sudo rm -rf ./latestmodel/*/*.model
        sudo cp -avr ./latestmodel/* ./ModelService/modelfiles/usecases/
        sudo rm -rf ./latestmodel/*
    fi
    '''
}

def buildDockerImage () {
    dir('ModelService') {
        sh label: '', script: '''
        docker container inspect ${CONTAINER_NAME} >/dev/null 2>&1 && \
            docker kill ${CONTAINER_NAME}
        docker image prune -a -f
        sudo docker build --tag ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${BUILD_NUMBER} .'''
    }
}

def pushDockerImageToDockerHub () {
    dir('ModelService') {
        withCredentials([usernamePassword(credentialsId: 'DockerHub', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
            sh label: '', script: '''
            docker login -u $USERNAME -p $PASSWORD
            docker push ${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${BUILD_NUMBER}'''
        }
    }
}

def deployContainerInGKE () {
    dir('ModelService') {
        withCredentials([usernamePassword(credentialsId: 'DockerHub', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
           script {
               env.DOCKERHUB_USERNAME_ENCODED=sh([ script: 'echo -n $USERNAME | base64', returnStdout: true ]).trim()
               env.DOCKERHUB_PASSWORD_ENCODED=sh([ script: 'echo -n $PASSWORD | base64', returnStdout: true ]).trim()
               echo "DOCKERHUB_USERNAME_ENCODED=${env.DOCKERHUB_USERNAME_ENCODED}";
               echo "DOCKERHUB_PASSWORD_ENCODED=${env.DOCKERHUB_PASSWORD_ENCODED}";
           }
        }
        sh label: '', script: '''
            sudo sed -i 's@<container_name>@'${CONTAINER_NAME}'@g' deployment.yaml
            sudo sed -i 's@<image:latest>@'${DOCKERHUB_USER}'/'${DOCKERHUB_REPO}':'${BUILD_NUMBER}'@g' deployment.yaml
            ''' 
        step([$class: 'KubernetesEngineBuilder', 
            projectId: env.PROJECT_ID,
            clusterName: env.CLUSTER_NAME,
            zone: env.LOCATION,
            manifestPattern: 'deployment.yaml/',
            credentialsId: env.CREDENTIALS_ID])
    }
}

def executeOnBuildSuccess () {
    echo "LATEST_MODEL_USECASE_ID=$LATEST_MODEL_USECASE_ID";
    withAWS(credentials: 'aws-devops', region: 'us-east-2') {
        sh label: '', script: '''
        if [ -n "$LATEST_MODEL_USECASE_ID" ]; then
            aws s3 mv s3://latest-model/$LATEST_MODEL_USECASE_ID.zip s3://history-model/${LATEST_MODEL_USECASE_ID}.zip
        fi
        '''
    }
    try {
        def successPayLoad = """
        {"usecase_id":"$LATEST_MODEL_USECASE_ID","model_id":"$LATEST_MODEL_NAME","completed": true,"step":"deploy","success":true,"msg":"deployment completed successfully","type": "deploy"}
        """
        httpRequest httpMode: 'POST', customHeaders: [[name: 'Content-Type', value: 'application/json'],[name: 'Verification', value: 'E1D1567C1832387FAC911C2FADB9D-$']], requestBody: successPayLoad, url: env.POST_BUILD_URL
    }
    catch (Exception ex) {
        echo 'downstream service unavailable'
    }
}

def executeOnBuildFailure () {
    withAWS(credentials: 'aws-devops', region: 'us-east-2') {
        sh label: '', script: '''
        if [ -n "$LATEST_MODEL_USECASE_ID" ]; then
            aws s3 mv s3://latest-model/$LATEST_MODEL_USECASE_ID.zip s3://history-model/${LATEST_MODEL_USECASE_ID}.zip --metadata-directive REPLACE --metadata '{"status":"inactive"}'
        fi
        '''
    }
    try {
        def failurePayLoad = """
        {"usecase_id":"$LATEST_MODEL_USECASE_ID","model_id":"$LATEST_MODEL_NAME","completed": true,"step":"deploy","success":false,"msg":"deployment completed unsuccesfully","type": "deploy"}
        """
        httpRequest httpMode: 'POST', customHeaders: [[name: 'Content-Type', value: 'application/json'],[name: 'Verification', value: 'E1D1567C1832387FAC911C2FADB9D-$']], requestBody: failurePayLoad, url: env.POST_BUILD_URL
    }
    catch (Exception ex) {
        echo 'downstream service unavailable'
    }
    }

def notifyPipelineBeginning () {
    try {
        def pipelineStartedPayLoad = """
        {"usecase_id":"$LATEST_MODEL_USECASE_ID","model_id":"$LATEST_MODEL_NAME","completed": false,"step":"deploy","success":true,"msg":"Started deployment","type": "deploy"}
        """
        httpRequest httpMode: 'POST', timeout: 20, customHeaders: [[name: 'Content-Type', value: 'application/json'],[name: 'Verification', value: 'E1D1567C1832387FAC911C2FADB9D-$']], requestBody: pipelineStartedPayLoad, url: env.POST_BUILD_URL
    }
    catch (Exception ex) {
        echo 'downstream service unavailable'
    }
}

def notifyStageBeginStatus (STAGE, MESSAGE) {
    try {
        def stageBeginsPayLoad = """
        {"usecase_id":"$LATEST_MODEL_USECASE_ID","model_id":"$LATEST_MODEL_NAME","completed": false,"step":"$STAGE","success":true,"msg":"$MESSAGE","type": "deploy"}
        """
        httpRequest httpMode: 'POST', customHeaders: [[name: 'Content-Type', value: 'application/json'],[name: 'Verification', value: 'E1D1567C1832387FAC911C2FADB9D-$']], requestBody: stageBeginsPayLoad, url: env.POST_BUILD_URL
    }
    catch (Exception ex) {
        echo 'downstream service unavailable'
    }
}

def notifyStageSuccessStatus (STAGE, MESSAGE) {
    try {
        def stageCompletePayLoad = """
        {"usecase_id":"$LATEST_MODEL_USECASE_ID","model_id":"$LATEST_MODEL_NAME","completed": true,"step":"$STAGE","success":true,"msg":"$MESSAGE","type": "deploy"}
        """
        httpRequest httpMode: 'POST', customHeaders: [[name: 'Content-Type', value: 'application/json'],[name: 'Verification', value: 'E1D1567C1832387FAC911C2FADB9D-$']], requestBody: stageCompletePayLoad, url: env.POST_BUILD_URL
    }
    catch (Exception ex) {
        echo 'downstream service unavailable'
    }
}

def notifyStageFailureStatus (STAGE, MESSAGE) {
    try {
        def stageFailurePayLoad = """
        {"usecase_id":"$LATEST_MODEL_USECASE_ID","model_id":"$LATEST_MODEL_NAME","completed": true,"step":"$STAGE","success":false,"msg":"$MESSAGE","type": "deploy"}
        """
        httpRequest httpMode: 'POST', customHeaders: [[name: 'Content-Type', value: 'application/json'],[name: 'Verification', value: 'E1D1567C1832387FAC911C2FADB9D-$']], requestBody: stageFailurePayLoad, url: env.POST_BUILD_URL
    }
    catch (Exception ex) {
        echo 'downstream service unavailable'
    }
}
