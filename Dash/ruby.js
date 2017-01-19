function replaceAll(str, find, replace)
{
    return str.replace(new RegExp(find, 'g'), replace);
}

var documentation = document.getElementById('documentation');
if(documentation)
{
    var classes = documentation.getElementsByClassName('class');
    var isModule = false;
    if(!classes || !classes.length)
    {
        classes = documentation.getElementsByClassName('module');
        isModule = true;
    }
    for(var i = 0; i < classes.length; i++)
    {
        var aClass = classes[i];
        aClass.setAttribute("class", aClass.getAttribute('class')+" class-loaded");
        var parent = document.createElement('span');
        var parentClassHTML = "None.";
        var parentSection = document.getElementById('parent-class-section');
        if(parentSection)
        {
            var links = parentSection.getElementsByClassName('link');
            if(links.length)
            {
                var link = links[0];
                if(link.innerText && link.innerText.trim().length)
                {
                    parentClassHTML = link.innerText.trim();
                    var anchors = link.getElementsByTagName('a');
                    var anchor = (anchors.length) ? anchors[0] : false;
                    var href = (anchor) ? anchor.getAttribute('href') : false;
                    if(href && href.length)
                    {
                        parentClassHTML = "<a class='rubyDashNamespaceClass' href='"+href+"'>"+parentClassHTML+"</a>.";
                    }
                    else
                    {
                        parentClassHTML = parentClassHTML+".";
                    }
                }
            }
        }
        var namespaceHTML = "";
        var namespaceSection = document.getElementById('namespace-list-section');
        if(namespaceSection)
        {
            var namespaceLinks = namespaceSection.getElementsByTagName('a');
            var addedMultipleNamespaces = false;
            for(var j = 0; j < namespaceLinks.length; j++)
            {
                var link = namespaceLinks[j];
                if(link.innerText && link.innerText.length)
                {
                    var namespaceText = link.innerText;
                    var href = link.getAttribute('href');
                    if(namespaceText && namespaceText.length && href && href.length)
                    {
                        if(namespaceHTML.length)
                        {
                            addedMultipleNamespaces = true;
                            namespaceHTML = namespaceHTML+", ";
                        }
                        var previousText = link.previousElementSibling.innerText;
                        var type = (previousText.toUpperCase() === "MODULE") ? "rubyDashNamespaceModule" : "rubyDashNamespaceClass";
                        namespaceHTML = namespaceHTML+"<a class='"+type+"' href='"+href+"'>"+namespaceText+"</a>";
                    }
                }
            }
        }
        if(namespaceHTML.length)
        {
            if(addedMultipleNamespaces)
            {
                namespaceHTML = " Namespaces: <a href='#' onclick='this.outerHTML = \""+replaceAll(replaceAll(namespaceHTML, "'", "\""), '"', '\\"')+"\"; return false;'>Show</a>.";
            }
            else
            {
                namespaceHTML = " Namespace: "+namespaceHTML+".";
            }
        }
        
        var includedHTML = "";
        var includesSection = document.getElementById('includes-section');
        if(includesSection)
        {
            var includeLinks = includesSection.getElementsByClassName('include');
            var addedMultipleIncludes = false;
            for(var j = 0; j < includeLinks.length; j++)
            {
                var link = includeLinks[j];
                if(link.innerText && link.innerText.length)
                {
                    var includeText = link.innerText;
                    var href = link.getAttribute('href');
                    if(includeText && includeText.length && href && href.length)
                    {
                        if(includedHTML.length)
                        {
                            addedMultipleIncludes = true;
                            includedHTML = includedHTML + ", ";
                        }
                        includedHTML = includedHTML+"<a class=\"rubyDashNamespaceModule\" href=\""+href+"\">"+includeText+"</a>";
                    }
                }
            }
        }
        if(namespaceHTML && namespaceHTML.length && isModule && !includedHTML.length)
        {
            namespaceHTML = namespaceHTML.trim();
        }
        if(includedHTML.length)
        {
            if(addedMultipleIncludes)
            {
                includedHTML = "Included Modules: <a href='#' onclick='this.outerHTML = \""+replaceAll(replaceAll(includedHTML, "'", "\""), '"', '\\"')+"\"; return false;'>Show</a>.";
            }
            else
            {
                includedHTML = "Included Modules: "+includedHTML+".";
            }
            if(!isModule)
            {
                includedHTML = " "+includedHTML;
            }
        }
        var appendHTML = "Parent Class: "+parentClassHTML+includedHTML;
        if(isModule)
        {
            appendHTML = includedHTML;
        }
        if(namespaceHTML.length)
        {
            appendHTML = appendHTML+namespaceHTML;
        }
        if(!appendHTML.length)
        {
            appendHTML = "&nbsp;";
        }
        parent.innerHTML = appendHTML;
        aClass.appendChild(parent);
    }
}
