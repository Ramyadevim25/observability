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
        git branch: 'main', url: 'https://github.com/YOUR_USERNAME/observability.git'
      }
    }

    stage('Start LocalStack') {
      steps {
        dir('Terraform_infra') {
          sh 'docker-compose up -d'
        }
        sleep time: 20, unit: 'SECONDS'
      }
    }

    stage('Terraform Init & Apply (Infra Only)') {
      steps {
        dir('Terraform_infra') {
          sh 'terraform init'
          sh 'terraform apply -auto-approve'
        }
      }
    }

    stage('Export Terraform Output for Simulator') {
      steps {
        dir('Terraform_infra') {
          sh 'terraform output -json > ../simulator/infra_output.json'
        }
      }
    }

    stage('Start Log Simulator') {
      steps {
        dir('simulator') {
          // Make sure Go is installed
          sh 'nohup go run log_simulator.go > logs/simulator.log 2>&1 &'
        }
      }
    }

    stage('Deploy Observability Stack (Terraform + Docker)') {
      steps {
        dir('observability_stack') {
          sh 'terraform init'
          sh 'terraform apply -auto-approve'
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
