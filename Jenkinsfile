pipeline {
   agent any

   environment {
     AUTOBUILD_ENABLE    = 'YES'
     AUTOBUILD_NUMBER    = "${BUILD_NUMBER}"
     AUTOBUILD_DATE      = "${BUILD_ID}"
     AUTOBUILD_JOBNAME   = "${JOB_NAME}"
     AUTOBUILD_GITCOMMIT = "${GIT_COMMIT}"
     AUTOBUILD_GITBRANCH = "${GIT_BRANCH}"
   }

   stages {
      stage("Prepare") {
         steps {
            echo "Prepare"
            echo "AUTOBUILD_ENABLE    = ${AUTOBUILD_ENABLE}"
            echo "AUTOBUILD_NUMBER    = ${AUTOBUILD_NUMBER}"
            echo "AUTOBUILD_DATE      = ${AUTOBUILD_DATE}"
            echo "AUTOBUILD_JOBNAME   = ${AUTOBUILD_JOBNAME}"
            echo "AUTOBUILD_GITCOMMIT = ${AUTOBUILD_GITCOMMIT}"
            echo "AUTOBUILD_GITBRANCH = ${AUTOBUILD_GITBRANCH}"
         }
      }
      stage("build") {
         steps {
            echo "build"
            sh 'bash ./src/sh/jenkinstest.sh'
            sh 'printenv'
         }
      }
      stage("Artifacts") {
         steps {
            echo "Artifacts"
         }
      }
   }
   post {
      // 完了ステータスに関係なく実行
      always {
        // ワークスペースを削除
        cleanWs()
      }
    }
}
