var feeds_information = [];

$(function () {
    $("#edit_feed_select").change(function() {
        var feed = feeds[$(this).val()];
        if (feed != null) {
            $("#edit_feed_name").val(feed.name);
            $("#edit_feed_category").val(feed.category);
            $("#edit_feed_display_content").attr('checked', feed.display_content);
            $("#edit_feed_public").attr('checked', feed.public);
        }
    });
    if ($("#readerFeedsInfo").length > 0) {
        $.get('/reader/feeds_info', function(data) {
            feeds_information = data;
            var result = '<ul><a id="displayAll" href="#" onclick="displayAll(); return false">All</a>';
            $.each(feeds_information, function(i, category) {

                var itemsCount = category[2];
                var isCategoryEmpty = (!itemsCount) || (itemsCount == 0);
                var categoryName = category[0];

                result += '<li class="categoryLi" id="category_' + i + '">\n';
                result += '\t<a id="categoryExpander_' + i + '" class="categoryExpander" onclick="clickExpander(' + i + '); return false" href="#">+</a>\n';
                result += '\t<a href="#" class="category' + (isCategoryEmpty ? '' : ' categoryWithElements' ) + '" onclick="displayCategory(\'' + categoryName + '\'); return false;">' + categoryName + '</a>';
                if (! isCategoryEmpty) {
                    result += ' (' + itemsCount + ')';
                }
                result += '\n\t<ul class="feedUL">\n';
                $.each(category[1], function (i, feed) {
                    var isFeedEmpty = (feed.count == 0);
                    result += '\t\t<li class="feedLi">~ ';
                    result += '<a href="#" id="feed_' + feed.id + '" class="feed' + (isFeedEmpty ? '' : ' feedWithElements') + '" onclick="displayFeed(' + feed.id + '); return false;">' + feed.name;
                    if (!isFeedEmpty) {
                        result += ' (' + feed.count + ')';
                    }
                    result += '</a>';
                    result += '</li>\n';
                });
                result += '\t</ul>\n</li>\n';
            });
            result += '</ul>';
            $("#readerFeedsInfo").append(result);
        });
    }
});

function clickExpander(i) {
    var categoryExpander = $("#categoryExpander_" + i);
    if (categoryExpander.html() == "+") {
        // will expand
        $("#category_" + i + " > ul").slideDown(function() {
            categoryExpander.html("–");
        });
    } else {
        // will collapse
        $("#category_" + i + " > ul").slideUp(function() {
            categoryExpander.html('+');
        });
    }
}

function displayAll() {
    
}

function displayCategory(name) {

}

function displayFeed(id) {

}