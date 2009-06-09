/*
 * Common methods for webdialogs.
 *
 * Requires jQuery
 */


// Loops over all input elements and ensure that they get an .focus class added upon focus and
// remove it when it loses focus. This is a workaround for IE7's lack of :hover support.
function add_focus_property()
{
	$('input').each( function(i)
	{
		$(this).focus(function ()
		{
			$(this).addClass('focus');
		});
		$(this).blur(function ()
		{
			$(this).removeClass('focus');
		});
	});
}