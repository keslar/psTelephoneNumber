@{
    Severity     = @(
        'Error', 
        'Warning'
    )


    ExcludeRules = @(   'PSAvoidGlobalVars', 
        'PSAvoidUsingDeprecatedManifestFields', 
        'PSPossibleIncorrectUsageOfAssignmentOperator', 
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseOutputTypeCorrectly',
        'PSUseSingularNouns',
        'TypeNotFound'

    )
}
