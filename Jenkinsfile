#!groovy
/*
 * Copyright (c) 2022. Faurecia Clarion Electronics All rights reserved.
 */

// Jenkinsfile for the seed job

// Import required libraries, PipelineUtils and repoci are fce librairies preloaded in Jenkins
import groovy.transform.Field
library "PipelineUtils"
library "repoci"

@Field def Credentials = null
@Field def credentialsId = [:]
@Field DockerList = []

assert (scm.branches.size() == 1) : "One and only one item shall be provided as scm.branches = /${scm.branches}/ !"
final String ciBranch = (String) scm.branches[0]
final String ciPrefix = (ciBranch != 'master' && ciBranch != 'origin/master') ? cleanCiBranchName(ciBranch) + '__' : ''

properties([
  pipelineTriggers([pollSCM('H/5 * * * *')]),
  disableConcurrentBuilds(),
  parameters([
      booleanParam(name: 'DISABLE_DOCKER_CACHE',
                   defaultValue: false,
                   description: "Force build docker image from scratch - Regenerate all docker layers" ),
      booleanParam(name: 'GENERATE_SILENT_JOBS',
                   defaultValue: false,
                   description: "Disable notification done by jobs - Usefull when in a sandbox" )
  ])
])

/*
 * Return true if the path is modified in the last git commit of the current directory
 */
def isPathModified(String path) {
    return sh(returnStatus: true, script: """git diff --name-only HEAD~ | grep -e "^$path" """) == 0
}

node('master') { timestamps { ansiColor('xterm') {

    // Get the credentials Id adapted to the running Jenkins server
    checkout scm
    Credentials = load('src/main/groovy/Credentials.groovy')
    def credentialList = Credentials.getServiceList()
    credentialList.each { service ->
        credentialsId[service] = Credentials.getCredentialIdFor(service)
    }
    // Get the crony2 dockers list from the 'envs' dir sub-dir list
    DockerList = getDirList ('envs')

    stage('Checkout') {
        cleanWs()
        checkout scm
        stash name: 'code', useDefaultExcludes: true
    }

    stage('Jobs') {
        jobDsl additionalClasspath: 'src/main/groovy',
               additionalParameters: [
                   'silentJob': isSandbox(env.BUILD_URL) || params.GENERATE_SILENT_JOBS,
                   'credentialsId': credentialsId,
                   'ciBranch': ciBranch,
                   'ciPrefix': ciPrefix,
               ],
               lookupStrategy: 'SEED_JOB',
               targets: [ findFiles(glob: 'jobs/**') ].flatten().join('\n')
    }

    // TODO: Move these 3 docker related sections to a specific "envs" job !!.
    stage('Publish docker templates from generic inherited images') {
        /* publishing should be done before the update as we need 'crony2-docker-slave' node */
        publishDockerTemplates templates: [
            [
                image: 'registry.pfa.fr.corp:5000/tools/jenkins-docker-slave:latest',
                label: 'crony2-docker-slave',
                features: [ docker: true ],
            ], [
                image: 'registry.pfa.fr.corp:5000/tools/jenkins-slave:latest',
                label: 'crony2-jenkins-slave',
            ]
        ]
    }

    /*
     * Only build the docker images if one of the Dockerfile was modified or
     * if the job forced the build
     * If triggered, the build is done on the swarm
     * Note that the swarm doesn't have any cache
     */
    stage('Update Crony2 docker images') {
        if (params.DISABLE_DOCKER_CACHE || isPathModified('envs')) {
            node('crony2-docker-slave') {
                /* build docker image(s) on the swarm to reduce CPU load and disk space on master server */
                unstash 'code'
                updateDockerEnvs path: 'envs',
                                 namespace: 'crony2',
                                 registryCredentials: credentialsId['registry'],
                                 buildParams: params.DISABLE_DOCKER_CACHE ? '--no-cache' : '',
                                 publishDockerTemplates: false
            }
        } else {
            // TODO: indicate the stage as "skipped" for a more relevant view of executed stages in BlueOcean view
        }
    }

    stage('Publish Crony2 docker agent templates') {
        def templateUpdateList = []
        DockerList.each { docker ->
            templateUpdateList.add makeCrony2DockerTemplateUpdateInfo(docker)
        }

        publishDockerTemplates templates: templateUpdateList
    }
} } } // node('master') { timestamps { ansiColor('xterm') {

/**
 * Creates a map for docker template agent configuration.
 * 
 * @param dockerName the name of the Docker image
 * @return a map containing the following informations:
 *         - 'image': the full image name, including the registry and tag
 *         - 'label': the template label
 *         - 'features': a map of features (docker, tmpfs_tmp...) loaded from envs/$dockerName/features.groovy if it exists

 */
def makeCrony2DockerTemplateUpdateInfo(String dockerName) {
    final dockerImage  = "crony2/$dockerName:latest"
    final template = "crony2-$dockerName"
    def featuresMap = []

    try {
        featuresMap = load("envs/$dockerName/features.groovy").dockerTemplateAgentFeatures
    } catch (Exception e) {
        println("No config file found for docker agent template features.")
    }

    [
        image: 'registry.pfa.fr.corp:5000/' + dockerImage,
        label: template,
        features: featuresMap
    ]
}

def cleanCiBranchName(String my_ciBranch) {
    final String forbidenCharToReplace = "?*/\\%!@#\$^&|<>[]:;"
    def returnString = ''

    for( int i=0; i < my_ciBranch.length(); i++ ) {
        String ch =  my_ciBranch.charAt(i);
        if (/*Character.isISOControl(ch) ||*/ (forbidenCharToReplace.indexOf(ch)!=-1)) {
            returnString += '_'
        } else {
            returnString += ch
        }
    }
    return returnString
}

def getDirList (String dir) {
    def dList = sh (returnStdout: true, script:"cd ${dir} && ls -d *").trim().split(/\s+/)
    return dList
}
