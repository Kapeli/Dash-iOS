var languages = document.getElementsByClassName("languages-list-item");
for(var i = 0; i < languages.length; i++)
{
    var language = languages[i];
    var links = language.getElementsByTagName("a");
    if(links.length && language.className.indexOf("current-language") == -1)
    {
        var link = links[0];
        link.onclick = function() { window.dash.newSwitchAppleLanguage(link.innerText); };
    }
}
