pipeline {
   agent any

   environment {
     AUTOBUILD_ENABLE = 'YES'
     AUTOBUILD_NUMBER = "${BUILD_NUMBER}"
   }

   stages {
      stage("Prepare") {
         steps {
            echo "Prepare"
            echo "AUTOBUILD_ENABLE = ${AUTOBUILD_ENABLE}"
            echo "AUTOBUILD_NUMBER = ${AUTOBUILD_NUMBER}"
         }
      }
      stage("build") {
         steps {
            echo "build"
            sh 'bash ./src/sh/jenkinstest.sh'
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
