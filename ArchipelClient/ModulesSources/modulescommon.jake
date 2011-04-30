/*  
 * modulescommon.jake
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


/* YOU SHOULD NOT HAVE TO CHANGE THE FOLLOWING */
var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake");
    task = JAKE.task,
    FileList = require("jake").FileList,
    framework = require("cappuccino/jake").framework,
    configuration = ENV["CONFIG"] || "Debug",
    OS = require("os"),
    FILELIST = (typeof(FILELIST) == "undefined") ?  new FileList("*.j") : FILELIST;

framework (NAME, function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", NAME + ".build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));
    task.setPreventsNib2Cib(true);
    task.setProductName(NAME);
    task.setIdentifier( COMPANY + "." + NAME);
    task.setVersion(VERSION);
    task.setAuthor(AUTHOR);
    task.setEmail(EMAIL);
    task.setSummary(SUMMARY);
    task.setSources(FILELIST);
    task.setResources(new FileList("Resources/**/**"));
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", [NAME], function()
{
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIG"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIG"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", NAME));
    OS.system(["press", "-f", "-v", "-F", "/../../../../../Frameworks/", FILE.join("Build", "Release", NAME), FILE.join("Build", "Deployment", NAME)]);
    printResults("Deployment")
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, NAME));
    print("----------------------------");
}
