folder("Whanos base images") {
    description("The base images of whanos.")
}

folder("Projects") {
    description("The available projets in whanos.")
}

languages = ["c", "java", "javascript", "python", "befunge", "cpp", "brainfuck"]

languages.each { language ->
    freeStyleJob("Whanos base images/whanos-$language") {
        steps {
            shell("docker build /images/$language -f /images/$language/Dockerfile.base -t whanos-$language")
        }
    }
}

freeStyleJob("Whanos base images/Build all base images") {
    publishers {
        downstream(
                languages.collect { language -> "Whanos base images/whanos-$language" }
        )
    }
}

freeStyleJob("link-project") {
    parameters {
        stringParam("GIT_URL", null, 'Git repository url')
        stringParam("DISPLAY_NAME", null, "Display name for the job")
    }
    steps {
        dsl {
            text('''
				freeStyleJob("Projects/$DISPLAY_NAME") {
					scm {
						git {
							remote {
								name("origin")
								url("$GIT_URL")
							}
						}
					}
					triggers {
						scm("* * * * *")
					}
					wrappers {
						preBuildCleanup()
					}
					steps {
						shell("/jenkins/deploy.sh \\"$DISPLAY_NAME\\"")
					}
				}
			''')
        }
    }
}