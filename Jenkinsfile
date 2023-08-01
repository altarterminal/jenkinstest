pipeline {
   agent any
   stages {
      stage("Prepare") {
         steps {
            echo "Prepare"
         }
      }
      stage("build") {
         steps {
            echo "build"
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
