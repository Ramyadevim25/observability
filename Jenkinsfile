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
          // Ensure 'logs' directory exists BEFORE redirecting output
          bat '''
          if not exist logs mkdir logs
          start /B go run log_simulator.go > logs\\simulator.log 2>&1
          '''
        }
      }
    }

    stage('Deploy Observability Stack (Terraform + Docker)') {
      steps {
        dir('observability_stack') {
          bat 'terraform init'
          bat 'terraform destroy -auto-approve || exit 0'
          bat 'terraform apply -auto-approve'
        }
        sleep time: 30, unit: 'SECONDS' // Wait for services to come online
      }
    }

    stage('Verify Observability Interfaces') {
      steps {
        echo "Grafana: http://localhost:3000"
        echo "Kibana: http://localhost:15601"
        echo "Log files: simulator/logs/"
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
