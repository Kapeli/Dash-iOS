function dashSetUpMSDN(prefs)
{
    if(prefs && prefs.length)
    {
        var topPref = prefs[0];
        var tabs = document.getElementsByClassName("codeSnippetContainerTab");
        for(var i = 0; i < tabs.length; i++)
        {
            var tab = tabs[i];
            var anchors = tab.getElementsWithTagName("a");
            var anchor = (anchors && anchors.length) ? anchors[0] : nil;
            if(anchor && anchor.innerText.toUpperCase() === topPref.toUpperCase())
            {
                makeActive(anchor);
            }
        }
        if(prefs.length > 1)
        {
            
        }
    }
}

oldMakeActive = makeActive; makeActive = function(s) { oldMakeActive(s); window.dash.msdnMakeActive(s)}