var language = document.getElementById('language');
if(language)
{
    var labels = language.getElementsByTagName('label');
    for(var i = 0; i < labels.length; i++)
    {
        var label = labels[i];
        label.setAttribute("onclick", "window.dash.switchAppleLanguage(this.getAttribute('for'))");
    }
}

function toggleOverviews()
{
    var toggles = document.getElementsByClassName('overview-bulk-toggle');
    for(var i = 0; i < toggles.length; i++)
    {
        toggles[i].setAttribute("style", "display:none !important;");
    }
    var bulks = document.getElementsByClassName('overview-bulk');
    for(var i = 0; i < bulks.length; i++)
    {
        bulks[i].setAttribute("style", "display:block !important;");
    }
}

var toggles = document.getElementsByClassName('overview-bulk-toggle');
for(var i = 0; i < toggles.length; i++)
{
    var toggle = toggles[i];
    toggle.setAttribute("onclick", "toggleOverviews()");
}

var collapsedTasks = document.getElementsByClassName('task');
for(var i = 0; i < collapsedTasks.length; i++)
{
    var collapsedTask = collapsedTasks[i];
    collapsedTask.setAttribute("onclick", "if(this.className.indexOf('closed') != -1) { this.className = 'task'; Array.prototype.forEach.call(this.getElementsByClassName('task-content'), function(el) { el.className = 'task-content showing'; } ); } else { this.className = 'task closed'; Array.prototype.forEach.call(this.getElementsByClassName('task-content'), function(el) { el.className = 'task-content'; } );}");
}
