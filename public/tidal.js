var displayedIds = [];

$(function () {
    $("#edit_feed_select").change(function () {
        var feed = feeds[$(this).val()];
        if (feed != null) {
            $("#edit_feed_name").val(feed.name);
            $("#edit_feed_category").val(feed.category);
            $("#edit_site_uri").val(feed.site_uri);
            $("#edit_feed_uri").val(feed.feed_uri);
            $("#edit_feed_display_content").attr('checked', feed.display_content);
            $("#edit_feed_public").attr('checked', feed.public);
        }
    });

    $('.postExpander').click(function () {
        var postExpander = $(this);
        var postId = postExpander.attr('id').substr(13);
        if (postExpander.html() == "+") {
            // will expand
            $("#post_" + postId).slideDown(function () {
                postExpander.html("–");
            });
        } else {
            // will collapse
            $("#post_" + postId).slideUp(function () {
                postExpander.html('+');
            });
        }
        return false;
    });
});
