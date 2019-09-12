pipepline{

	agent any

	stages{
		stage('Build'){
			steps{
				sh '''
           			echo "build step"
        		'''
				
			}
		}

		stage('Test'){
			step{
				sh '''
					echo "test step"
				'''
			}
		}


		stage('Deploy'){
			step{
				ssh '''
					echo "deply step"
				'''
			}
		}
	}
}
