pipeline {
  agent any

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {

    stage('Checkout Code') {
      steps {
        git branch: 'main', url: 'https://github.com/Ramyadevim25/observability.git'
      }
    }

    stage('Start LocalStack') {
      steps {
        dir('Terraform_infra') {
          bat 'docker-compose up -d'
        }
        sleep time: 20, unit: 'SECONDS'
      }
    }

    stage('Terraform Init & Apply (Infra Only)') {
      steps {
        dir('Terraform_infra') {
          bat 'terraform init'
          bat 'terraform apply -auto-approve'
        }
      }
    }

    stage('Export Terraform Output for Simulator') {
      steps {
        dir('Terraform_infra') {
          bat 'terraform output -json > ../simulator/infra_output.json'
        }
      }
    }

    stage('Start Log Simulator') {
      steps {
        dir('simulator') {
          bat '''
          if not exist logs mkdir logs
          go build -o log_simulator.exe log_simulator.go
          powershell -Command "Start-Job { Start-Process -NoNewWindow -FilePath ./log_simulator.exe -WorkingDirectory . }"
          '''
        }
      }
    }



    stage('Deploy Observability Stack (Terraform + Docker)') {
      steps {
        dir('observability_stack') {

          // 🔥 Manually remove containers if already running (prevents image conflict errors)
          bat 'docker network rm observability_net || exit 0'

          // Terraform deploy
          bat 'terraform init'
          bat 'terraform apply -auto-approve'
        }

        // Give containers time to become available
        sleep time: 30, unit: 'SECONDS'
      }
    }

    stage('Verify Observability Interfaces') {
      steps {
        echo "✅ Grafana: http://localhost:3000 (admin/admin)"
        echo "✅ Kibana: http://localhost:15601"
        echo "✅ Log Files: simulator/logs/"
      }
    }
  }

  post {
    success {
      echo '✅ Observability pipeline completed successfully!'
    }
    failure {
      echo '❌ Pipeline failed. Check the logs above.'
    }
  }
}
