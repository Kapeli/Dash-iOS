var hash = window.location.hash;
hash = hash.replace(/^#/, '');
var didScroll = false;
if(hash && hash.length)
{
    var anchor = document.anchors.namedItem(hash);
    anchor = (anchor) ? anchor : document.getElementById(hash);
    if(anchor)
    {
        didScroll = true;
        anchor.scrollIntoView();
    }
}
if(!didScroll)
{
    window.scrollTo(0,0);
}