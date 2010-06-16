$(function () {
    $("#edit_feed_select").change(function() {
        var feed = feeds[$(this).val()];
        if(feed != null) {
            $("#edit_feed_name").val(feed.name);
            $("#edit_feed_category").val(feed.category);
            $("#edit_feed_display_content").attr('checked', feed.display_content);
            $("#edit_feed_public").attr('checked', feed.public);
        }
    });
});
