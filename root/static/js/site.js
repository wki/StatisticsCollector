/* site.js */

$(function() {
    var tipped_is_installed = window.Tipped ? true : false;
    
    $('._submit_on_change').on('change', function() {
        console.log('changed, must submit');
        $(this).parent('form').get(0).submit();
    });
    
    $('._show_graph').each( function() {
        var img = $(this).find('img.image[data-href]');
        if (!img.length) {
        } else if (tipped_is_installed) {
            img.removeClass('image'); // prevent CSS :hover from triggering
            var cloned_image = img.clone().css('width', 600).css('height', 400);
            Tipped.create($(this), 
                          cloned_image.get(0), 
                          {
                              onShow: function() {
                                  cloned_image.attr('src', img.attr('data-href'));
                              },
                              skin: 'light',
                              offset: { x: 0, y: 0 },
                              hook: 'righttop',
                          } );
        } else {
            $(this).on('hover', function() {
                img.attr('src', img.attr('data-href'));
                img.removeAttr('data-href');
            });
        }
    } );
});