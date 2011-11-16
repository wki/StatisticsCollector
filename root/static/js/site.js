/* site.js */

$(function() {
    $('._submit_on_change').on('change', function() {
        console.log('changed, must submit');
        $(this).parent('form').get(0).submit();
    });
    
    $('._show_graph').on('hover', function() {
        var img = $(this).find('img.image[data-href]');
        if (img.length) {
            console.log('image will get set...');
            img.attr('src', img.attr('data-href'));
            img.removeAttr('data-href');
        }
    });
});