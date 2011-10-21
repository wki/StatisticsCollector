/* site.js */

$(function() {
    $('._submit_on_change').change(function() {
        console.log('changed, must submit');
        $(this).parent('form').get(0).submit();
    });
});