$(document).ready(init)


function init()
{
	// Usual enhancements
	add_focus_property();
	// Add illustration effects
	illustrate();
	// Add callbacks
	add_callbacks();
}


// This will display an illustration for each input element.
function illustrate()
{
	$('input').each( function(i)
	{
		$(this).focus( function()
		{
			var image = $( '#img' + this.id.substr(3) )
			image.css('z-index', '1');
			image.fadeIn(400);
			/*image.fadeIn(400, function()
			{
				$('#illustration img').not(image).hide();
				// (!) Don't do this when we fade out with delay.
			});
			*/
		});
		$(this).blur( function()
		{
			var image = $( '#img' + this.id.substr(3) )
			image.css('z-index', '0');
			// Fade out after an delay. We delay so that we allow the fadeIn to overlap the old
			// image.
			window.setTimeout(function()
			{
				image.fadeOut(400)
			}, 400);
		});
	});
}

function add_callbacks()
{
	$('#cmdGenerate').click( param_generate );
	$('#cmdCancel').click( function() { window.location = 'skp:param_cancel'; } );
}

function param_generate()
{
	var params = [];
	params.push('road_width=' + $('#txtWidth').val() );
	params.push('corner_radius=' + $('#txtRadius').val() )
	params.push('min_round_angle=' + $('#txtAngleThreshold').val() );
	params.push('create_blocks=' + $('#chkBlocks').attr('checked') );
	window.location = 'skp:param_generate@' + params.join(',');
}