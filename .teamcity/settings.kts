import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.DockerSupportFeature
import jetbrains.buildServer.configs.kotlin.buildFeatures.GolangFeature
import jetbrains.buildServer.configs.kotlin.buildSteps.DockerCommandStep
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.projectFeatures.DockerRegistryConnection
import jetbrains.buildServer.configs.kotlin.projectFeatures.S3Storage
import jetbrains.buildServer.configs.kotlin.triggers.VcsTrigger
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2022.10"

/* -----------------------------------------------------------------------------
Root project definition goes here
------------------------------------------------------------------------------*/

project(RootProject)

object RootProject : Project({
    description = "Contains all other projects"

    features {
        feature(KubernetesDefaultCloudProfile)
        feature(KubernetesDefaultCloudImage)
        feature(DefaultS3ArtifactStorage)
        feature(DefaultDockerRegistry)
    }

    cleanup {
        baseRule {
            preventDependencyCleanup = false
        }
    }

    subProject(SampleGoProject)
})

object KubernetesDefaultCloudProfile : KubernetesCloudProfile({
    id = "DefaultCloudProfileID"
    name = "Root project default k8s cloud profile"
    // FIXME: Put in-cluster dns name of TeamCity server's service in the form
    // http://{svc name}.{namespace}[.svc.cluster.local]:{svc port}
    serverURL = "http://192.168.10.20:8111"
    terminateIdleMinutes = 30
    // FIXME: Put EKS API server endpoint from Terraform outputs
    apiServerURL = "http://192.168.10.20:8001"
//    authStrategy = eks {
//        useInstanceProfile = true
//        clusterName = "tc-eks-cluster"
//    }
    authStrategy = token {
        token = "credentialsJSON:ad777d4d-b817-416d-8ea7-b94fffe20b44"
    }
})

object KubernetesDefaultCloudImage : KubernetesCloudImage({
    profileId = KubernetesDefaultCloudProfile.id
    agentNamePrefix = "k8s-agent"
    podSpecification = deploymentTemplate {
        deploymentName = "teamcity-stack-agent"
    }
})

// Probably it's better to configure bucket for each project individually, but
// here for simplification let's use the root one
object DefaultS3ArtifactStorage : S3Storage({
    id = "DefaultS3ArtifactStorageID"
    storageName = "Root project default S3 storage"
    bucketName = "teamcity-artifacts"

    // Region should be the same one as in Terraform
    awsEnvironment = default {
        awsRegionName = "eu-central-1"
    }

    // path-style is deprecated
    // https://aws.amazon.com/blogs/aws/amazon-s3-path-deprecation-plan-the-rest-of-the-story/
    forceVirtualHostAddressing = true

    // We'll use IAM role, attached to nodes
    useDefaultCredentialProviderChain = true
})

object DefaultDockerRegistry : DockerRegistryConnection({
    id = "DefaultDockerRegistryID"
    name = "Root project default docker registry"
    url = "https://docker.io"
    // FIXME: it's actually better to use in-cluster secret with docker credentials
    userName = "th30nlyw4y"
    // FIXME: change it to generated token
    password = "credentialsJSON:cb0cdea8-ac68-463d-8fe9-945dcea8ea8d"
})

/* -----------------------------------------------------------------------------
Go project definition goes here
------------------------------------------------------------------------------*/

object SampleGoProject : Project({
    id("SampleGoProjectID")
    name = "Sample Go project"
    vcsRoot(GoProjectVcsRoot)
    buildType(GoProjectBuild)
})

// Configure build steps for project here
object GoProjectBuild : BuildType({
    id("SampleGoProjectBuildID")
    name = "Build Go application"

    vcs {
        root(GoProjectVcsRoot)
    }

    steps {
        step(GoTest)
        step(DockerBuild)
        step(DockerPush)
    }

    triggers {
        trigger(SampleGoProjectVcsTrigger)
    }

    features {
        feature(SampleGoProjectGolang)
        feature(SampleGoProjectDockerSupport)
    }
})

// Configure project repo here
object GoProjectVcsRoot : GitVcsRoot({
    id("SampleGoProjectVCSRootID")
    // FIXME: change dummy project name to the real one
    name = "sample-go-project"
    // FIXME: change dummy repo url to the real one
    url = "https://github.com/th30nlyw4y/sample-go-project.git"
    branch = "main"
    branchSpec = "+:main"
    // FIXME: change it to generated token
    authMethod = password {
        password = "credentialsJSON:5ec475df-9526-4d61-9b38-9f82dc08f2e9"
    }
})

object GoTest : ScriptBuildStep({
    name = "Go Test"
    scriptContent = "go test -json ./..."
    dockerImage = "golang:1.20.4"
})

object DockerBuild : DockerCommandStep({
    name = "Docker build"
    commandType = build {
        source = file {
            path = "Dockerfile"
        }
        // FIXME: change dummy repo/tag to the real one
        namesAndTags = "th30nlyw4y/sample-go-app:latest"  // Put needed values here
    }
})

object DockerPush : DockerCommandStep({
    name = "Docker push"
    commandType = push {
        // FIXME: change dummy repo/tag to the real one
        namesAndTags = "th30nlyw4y/sample-go-app:latest"
    }
})

object SampleGoProjectVcsTrigger : VcsTrigger({
    branchFilter = "+:*"
})

object SampleGoProjectGolang : GolangFeature({
    testFormat = "json"
})

object SampleGoProjectDockerSupport : DockerSupportFeature({
    loginToRegistry = on {
        dockerRegistryId = DefaultDockerRegistry.id
    }
    cleanupPushedImages = true
})
