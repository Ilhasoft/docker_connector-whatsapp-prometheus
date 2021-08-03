import groovy.json.JsonOutput
import jenkins.plugins.rocketchatnotifier.model.MessageAttachment

List<String> messagesList=new ArrayList<String>();

pipeline {
    agent {label 'general'}

    parameters {
        // K8s and build params
        string(
            name: 'DOCKER_IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image version to be used'
        )
        booleanParam(
            name: 'ENABLE_BUILD',
            defaultValue: true,
            description: 'Build App'
        )
        //string(
        //    name: 'GIT_URL',
        //    defaultValue: 'https://github.com/Ilhasoft/docker_kukectl',
        //    description: 'Git Repository URL'
        //)
        //string(
        //    name: 'GIT_BRANCH',
        //    defaultValue: 'main',
        //    description: 'Git Repository BRANCH'
        //)
    }

    environment {
        DOCKER_IMAGE_NAME = "weniai/connector-whatsapp-prometheus"
    }

    stages{
        //stage('SCM') {
        //    steps{
        //        checkout poll: false,
        //        scm:
        //            [
        //                $class: 'GitSCM',
        //                branches: [
        //                    [name: "refs/heads/${params.GIT_BRANCH}"]
        //                ],
        //                doGenerateSubmoduleConfigurations: false,
        //                extensions: [[
        //                    $class: 'SubmoduleOption',
        //                    disableSubmodules: false,
        //                    parentCredentials: true,
        //                    recursiveSubmodules: false,
        //                    reference: '',
        //                    trackingSubmodules: false
        //                ]],
        //                //extensions: [],
        //                //submoduleCfg: [],
        //                userRemoteConfigs: [[
        //                    credentialsId: "github_baltazarweni",
        //                    url: "${params.GIT_URL}"
        //                ]]
        //            ]
        //    }
        //}
        stage('Build Image') {
            when {
                expression { params.ENABLE_BUILD }
            }
            steps {
                script {
                    //try {
                        docker.build("${env.DOCKER_IMAGE_NAME}")
                        rocketConcatMessage(true, messagesList)
                    //} catch (exc) {
                     //   rocketConcatMessage(false, messagesList)
                    //}
                }
            }
        }
        stage('Push Image') {
            when {
                expression { params.ENABLE_BUILD }
            }
            steps {
                script {
                    docker.withRegistry('', 'dockerhub_weni_admin') {
                        docker.image("${env.DOCKER_IMAGE_NAME}").push("${env.DOCKER_IMAGE_TAG}")
                    }
                }
            }
        }
    }
}

def rocketConcatMessage(success, messagesList) {
    script {
        def status = 'Failed'
        def color = 'red'

        if (success) {
            status = 'Success'    
            color = 'green'
        }
        messagesList.add("${color}, ${status}, ${env.STAGE_NAME}")

        if (success == false) {
            rocketSendMessage(messagesList)
            error 'Something failed...'
        }
    }
}

def rocketSendMessage(messagesList) {
    script {
        def avatar_failed = 'https://push-inbox.s3.amazonaws.com/logos/jenkins/rage.png'
        def avatar = 'https://push-inbox.s3.amazonaws.com/logos/jenkins/good.png'

        def attachments = []
        def is_failed = false

        for (String i: messagesList) {
            message = i.split(', ')

            def attachment = [:]
            attachment['color'] = message[0]
            attachment['text'] = message[1]
            attachment['collapsed'] = false
            attachment['authorName'] = message[2]
            attachment['$class'] = 'MessageAttachment'

            attachments.add(attachment)

            if (message[1] == 'Failed') {
                avatar = avatar_failed
            }
        }

        rocketSend(
            channel: '#alerts-yellow',
            avatar: avatar,
            attachments: attachments,
            message: "*Pipeline:* ${env.JOB_NAME} \n\n :flag_br: (sa-east-1): *Build:* ${env.BUILD_NUMBER} \n :link: ${env.BUILD_URL}",
            rawMessage: true,
            failOnError: false
        )
    }
}

