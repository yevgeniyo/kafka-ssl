/*

1. This script will sign certificate by local CA and upload to S3:
    client.truststore.jks
    server.truststore.jks (will be created per server base on provided hostname)

2. Create A record for domain kafka.<example.com>

Parameters

VAULT_ADDR
VAULT_TOKEN
HOST_NAME (e.g. kafka1.data-infra)
BROKER_EXTERNAL_IP (e.g. ELASTIC ip of AWS instance or public IP of physical machine)
EMAIL_ADDRESS (for notification of failure)

*/



pipeline {

    agent {
        node { label 'docker-aws' }
    }

    options {
	    //withAWS(region: 'us-east-1', credentials:'kafka.ssl')
	    withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding',
                                credentialsId : 'kafka.ssl',
                                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]])
    }

    environment {
        CLUSTER_NAME_LIST = env.HOST_NAME.split("\\.")
        // CLUSTER_NAME - should be like data-infra.prod
        CLUSTER_NAME = [env.CLUSTER_NAME_LIST[1], env.CLUSTER_NAME_LIST[2]].join(".")
        // FULL_HOSTNAME - should be with format kafka1.<example.com>
        FULL_HOSTNAME = [env.HOST_NAME, "example.com"].join(".")
        // SERVER_NAME return kafka1, kafka2 etc
        SERVER_NAME = [env.CLUSTER_NAME_LIST[0]].join("")
        RESPONSE = " "
    }



    stages{

        stage('Generating certificates and upload to S3') {
            steps {
                  script{
                        try {

                            // Getting certificates from VAULT
                            sh """echo 'Getting certificates from VAULT' """

                            sh "echo ${env.FULL_HOSTNAME}"

                            sh """ export VAULT_ADDR=${env.VAULT_ADDR}"""
                            sh """ vault login ${env.VAULT_TOKEN} """
                            sh """ mkdir cert/ """
                            sh """#!/bin/bash
                               vault write kafka-datainfra/issue/servers common_name=${env.FULL_HOSTNAME} -format=json ttl=30000h | \
                               tee >(jq -r .data.certificate > cert/cert) \
                               >(jq -r .data.issuing_ca >> cert/CA.pem) \
                               >(jq -r .data.private_key > cert/key) 2>/dev/null
                               """



                            // Upload server.keystore.jks to S3://<bucket>/cluster name/server name/

                            sh """ aws s3 sync cert/ s3://<bucket>/${env.CLUSTER_NAME}/${env.FULL_HOSTNAME}/"""

                            currentBuild.result = 'SUCCESS'
                        } catch (any) {
                            currentBuild.result = 'FAILURE'
                            throw any //rethrow exception to prevent the build from proceeding
                        }
                      }
                  }
               }

        stage('Creating Record Set for .kafka.<example.com>') {
            steps {
                  script{
                        try {
                            sh """aws route53 change-resource-record-sets --hosted-zone-id <ID> --change-batch '{"Comment": "created automatically", "Changes": [{"Action": "CREATE","ResourceRecordSet": {"Name": "${env.FULL_HOSTNAME}","Type": "A","TTL": 600,"ResourceRecords": [{"Value": "${env.BROKER_EXTERNAL_IP}"}]}}]}'"""
                            currentBuild.result = 'SUCCESS'
                        } catch (any) {
                            currentBuild.result = 'FAILURE'
                            throw any //rethrow exception to prevent the build from proceeding
                        }
                      }
                  }
               }



        }



}