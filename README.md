# chocolatey-packages/docs
Chocolatey.org Package auto-updater for Jetbrains IDEA based IDEs

Note: The actual files for the build process are in separate branches.

# Structure (bold files need to be changed for new IDEs)
* __CheckBuildUpdate.ps1__ - Check for updates, replace markers in template files, pack the NUPKG
* __template.nuspec__ - Metadata / ToC file for the package (template markers are replaced and $product$.nuspec [i.e.: phpstorm.nuspec] is generated)
* appveyor.yml - Build descriptor for AppVeyor (Used for automated builds, triggered once per day using an external cronjob service)
* .gitattributes - Teach GitHub and others that ps1 files are text files and not binary data
* __.gitignore__ - do not commit generated files
* __tools/chocolateyInstall_template.ps1__ - template for the installer wrapper
* __tools/chocolateyUninstall_template.ps1__ - template for the uninstaller wrapper (get uninstall command from registry)
* tools/helper.ps1 - Helper functions (currently only a function to find the uninstaller command in the registry)

# How to modify for a new IDE
1. __Open CheckBuildUpdate.ps1__

1.1. Replace all occurences of phpstorm.nuspec by the package name of the new IDE

1.2. In line 23 replace the App-Code in the URL.   

1.2.1. To find out the right code, go to the product site at jetbrains.com and open the Network tab of your browser's DevTools (F12 in Firefox and Chrome). 

1.2.2. Reload the page to see all the different HTTP requests made by the site and look for a request to data.services.jetbrains.com/releases with several request parameters. 

1.2.3. Write down the 2/3 letter code parameter of that request/url. (i.e.: This is the URL called from the CLion product page https://data.services.jetbrains.com/products/releases?code=CL&latest=true&type=release&build=&_=151674495807 the code we're looking for is CL, but it's not always that easy to guess and doesn't neccessarily correspond to the shortcodes used in Jetbrains Bugtracker)

1.2.4. Change the PS (PhpStorm) code against whatever code you found out in the last step (Here: CL for Clion)

1.3. Replace the code from 1.2 in the variables that are filled from JSON path queries (i.e.: ll 24,75,78)

1.4. (optional) sometimes you might need the majorVersion to build some of the other URLs, add a new line after the newVersion variable declaration ```$majorVersion = $release.PS.majorVersion``` (remember to replace the Application Code again)

1.5. Adjust the Release Notes/Changelog URLs for the release of your preferred JetBrains product. (You'll have to find the URL and scheme for that by hand, they don't seem to follow any common pattern. PHPStorm for example has 1 changelog per final release inlcuding minor/patch versions, whereas PyCharm only has one changelog per major release that includes information for all minor/patch versions and EAP releases within that major version)

2. __Open template.nuspec__

2.1. Replace the unique package name inside the id field by the one for your IDE.

2.2. Replace the Title tag to correspond to your IDE

2.3. Pretty much all the other metadata subtags are optional. You can either replace or remove them completely. In the Description tag you may use markdown, but have to HTML-Entity-Encode all XML special-characters like &, <, >

2.4. the files part shouldn't require any changes by you

3. __Open the tools/chocolateyInstall_template.ps1__

3.1. Just replace the packageName variable

4. __Open the tools/chocolateyUninstall_template.ps1__

4.1. Replace the packageName variable and the query to look up the uninstaller in the registry (if unsure, just install the software and check what name it goes by in the Install/Uninstall software menu of "classic" control panel)


# Setting up auto-update deployment
I usually use AppVeyor to create the packages and upload them to chocolatey, so that's the process I'll explain here:

Create an account at AppVeyor and connect your Github account (or provide it with access to whatever repository you're using).
You can create a new project and pretty much leave all the default settings as we'll configure it using the appveyor.yml from the repository.
Just replace the API_KEY, the nuspec filename, branch names (usually master, but you can leave that bullet point away if you only have one branch) and email notifications settings.

Next grab an API token for AppVeyor (click on your account in the top-right corner and then choose API-Token from the dropdown menu)

Last but not least create a cronjob to automatically look for updates and deploy the new package on success:
For that I use https://cron-job.org/en/, because they're open source and have free scheduled HTTP requests.
Sign up for an account, go to the members area, create a new cronjob to run whenever you like (mine is set to run daily at 23:45).
You're free to choose any title you like.
Use https://ci.appveyor.com/api/builds as the target address and save the whole thing.
You need to go back and edit the cronjob again to get to the advanced settings.
There change the request mode from GET to POST, add the following POST Body:
`{
    accountName: 'BenediktBauer',
    projectSlug: 'chocolatey-packages',
    branch: 'phpstorm'
}`
(obviously adjust for your own accountName, projectSlug and branch)

Also add 2 custom headers:

__Header  =>  Value__

_Authorization_  =>  Bearer YOUR_API_TOKEN_HERE

_Content-Type_  => application/json


