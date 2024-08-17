Using Module UriBuilderPro

$geminiConfig = @{
    accessToken = $env:geminiKey
    getAvailableModels = 'https://generativelanguage.googleapis.com/v1beta/models'
    generateAttributed =  'https://generativelanguage.googleapis.com/v1beta/models/aqa:generateAnswer'
    generate = @{
        geminiPro = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'
        geminiFlash = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent' 
    }
}

function Invoke-GeminiApi { 
    Param(
        [Parameter(Mandatory=$true)]
        [UriBuilderPro]$EndpointObject,

        [Parameter(Mandatory=$false)]
        [String]$Method = 'GET',

        [Parameter(Mandatory=$true)]
        $Body
    )
    $EndpointObject.AddParameter('key',$geminiConfig.accessToken)

    $Headers = @{
        'Content-Type' = 'application/json'
    }

    $params = @{
        Uri = $EndpointObject.ToString()
        Method = $Method
        Headers = $Headers
    }
    If ($Body) {
        if (-Not ($Body -is [String])){
            Throw 'Error forming request; Body parameter is not of type string'
        } 
        $params.Body = $Body
    }

    Try {
        $response = Invoke-RestMethod -SkipHttpErrorCheck @params
        If ($response.error) {
            Throw "[Error] Calling API: $(ConvertTo-Json -InputObject $response)"
        }
        Else {
            Return $response
        }
    } Catch {
        return $_
        Write-Error "Error making API call: $($_.Exception.Message)"
    }
}

function Invoke-Gemini {
    param(
        [Parameter(Mandatory)]
        [String]$InputText
    )

    $requestBody = ConvertTo-Json -Depth 7 -InputObject @{
        contents = @(
            @{
                parts = @(
                        @{ text = $InputText}
                )
            }
        )
        safetySettings = @(
            @{
                category = "HARM_CATEGORY_DANGEROUS_CONTENT"
                threshold = "BLOCK_NONE"
            };
            @{
                category = "HARM_CATEGORY_HARASSMENT"
                threshold = "BLOCK_NONE"
            };
            @{
                category = "HARM_CATEGORY_HATE_SPEECH"
                threshold = "BLOCK_NONE"
            };
            @{
                category = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
                threshold = "BLOCK_NONE"
            }
        )
    }

    $builder = [UriBuilderPro]::new($geminiConfig.generate.geminiPro)
    $params = @{
        EndpointObject = $builder
        Method = 'POST'
        Body = $requestBody
    }
    function handleOutput {
        param(
            $InputObject
        )
        Write-Host -ForegroundColor 'Blue' -Object $InputObject.candidates.content.parts.text

    }
    handleOutput -InputObject (Invoke-GeminiApi @params)
}
Export-ModuleMember -Function 'Invoke-Gemini'


function Get-GeminiAvailableModels { 
    $builder = [UriBuilderPro]::new($geminiConfig.getAvailableModels)
    $params = @{
        EndpointObject = $builder
        Method = 'GET'
    }
    function handleOutput {
        param(
            $InputObject
        )
        return $InputObject.models
    }
    handleOutput -InputObject (Invoke-GeminiApi @params)
}
Export-ModuleMember -Function 'Get-GeminiAvailableModels'

function Invoke-GeminiAttributedFunction {
    param(
        [Parameter(Mandatory)]
        [String]$InputText
    )
    $requestBody = ConvertTo-Json -Depth 7 -InputObject @{
        contents = @(
            @{
                parts = @(
                        @{ text = $InputText}
                )
            }
        )
        safetySettings = @(
            @{
                category = "HARM_CATEGORY_DANGEROUS_CONTENT"
                threshold = "BLOCK_NONE"
            };
            @{
                category = "HARM_CATEGORY_HARASSMENT"
                threshold = "BLOCK_NONE"
            };
            @{
                category = "HARM_CATEGORY_HATE_SPEECH"
                threshold = "BLOCK_NONE"
            };
            @{
                category = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
                threshold = "BLOCK_NONE"
            }
        )
        answerStyle = "EXTRACTIVE"
    }

    $builder = [UriBuilderPro]::new($geminiConfig.generateAttributed)
    $params = @{
        EndpointObject = $builder
        Method = 'POST'
        Body = $requestBody
    }
    function handleOutput {
        param(
            $InputObject
        )
        Write-Host -ForegroundColor 'Blue' -Object $InputObject.candidates.content.parts.text
    }
    # handleOutput -InputObject (Invoke-GeminiApi @params)
    return Invoke-GeminiApi @params
}
Export-ModuleMember -Function 'Invoke-GeminiAttributedFunction'

