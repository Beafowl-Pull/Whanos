// Define folders
folder("Whanos base images") {
    description("The base images of whanos.")
}

folder("Projects") {
    description("The available projects in whanos.")
}

// Language array
def languages = ["c", "java", "javascript", "python", "befunge", "cpp", "brainfuck"] as java.lang.Object

// Function to create freeStyleJob for a language
def createLanguageJob(language) {
    freeStyleJob("Whanos base images/whanos-$language") {
        steps {
            shell("/jenkins/display_rand_wanos.sh")
            shell("docker build /images/$language -f /images/$language/Dockerfile.base -t whanos-$language")
        }
    }
}

// Create jobs for each language
languages.each { language ->
    createLanguageJob(language)
}

// Create a job to build all base images
freeStyleJob("Whanos base images/Build all base images") {
    publishers {
        downstream(languages.collect { "Whanos base images/whanos-$it" })
    }
}

// Create a job to link a project
freeStyleJob("link-project") {
    parameters {
        stringParam("GIT_URL", null, 'Git repository url')
        stringParam("DISPLAY_NAME", null, "Display name for the job")
    }
    steps {
        dsl {
            text('''freeStyleJob("Projects/$DISPLAY_NAME") {
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
