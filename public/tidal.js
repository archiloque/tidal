var feeds_information = [];
var displayedIds = [];

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

                var itemsCount = category.count;
                var isCategoryEmpty = (!itemsCount) || (itemsCount == 0);
                var categoryName = category.name;

                result += '<li class="categoryLi" id="categoryLi_' + i + '">\n'
                        + '\t<a id="categoryExpander_' + i + '" class="categoryExpander" onclick="clickCategoryExpander(' + i + '); return false" href="#">+</a>\n'
                        + '\t<a href="#" id="category_' + i + '" class="categoryInfo' + (isCategoryEmpty ? '' : ' categoryWithElements' ) + '" onclick="displayCategory(\'' + categoryName + '\'); return false;">' + categoryName;
                if (! isCategoryEmpty) {
                    result += ' (' + itemsCount + ')';
                }
                result += '</a>';
                result += '\n\t<ul class="feedUL">\n';
                $.each(category.feeds, function (i, feed) {
                    var isFeedEmpty = (feed.count == 0);
                    result += '\t\t<li class="feedLi">~ '
                            + '<a href="#" id="feed_' + feed.id + '" class="feedInfo' + (isFeedEmpty ? '' : ' feedWithElements') + '" onclick="displayFeed(' + feed.id + '); return false;">' + feed.name;
                    if (!isFeedEmpty) {
                        result += ' (' + feed.count + ')';
                    }
                    result += '</a>'
                            + '</li>\n';
                });
                result += '\t</ul>\n</li>\n';
            });
            result += '</ul>';
            $("#readerFeedsInfo").append(result);
        });
    }
});

function clickCategoryExpander(i) {
    var categoryExpander = $("#categoryExpander_" + i);
    if (categoryExpander.html() == "+") {
        // will expand
        $("#categoryLi_" + i + " > ul").slideDown(function() {
            categoryExpander.html("–");
        });
    } else {
        // will collapse
        $("#categoryLi_" + i + " > ul").slideUp(function() {
            categoryExpander.html('+');
        });
    }
}

function displayAll() {
    display("/reader/render/all", {}, function() {
        $.each(feeds_information, function(i, category) {
            // update the categories
            $("#category_" + i).removeClass("categoryWithElements").html(category.name);

            // update the feeds
            $.each(category.feeds, function (i, feed) {
                $("#feed_" + feed.id).removeClass("feedWithElements").html(feed.id.name);
            });
        });
    });
}

// display unread posts from this category
function displayCategory(name) {
    display("/reader/render/category", {name: name}, function() {
        // find the category
        $.each(feeds_information, function(i, category) {
            if (category.name == name) {

                // update the category
                $("#category_" + i).removeClass("categoryWithElements").html(name);

                // update the feeds
                $.each(category.feeds, function (i, feed) {
                    $("#feed_" + feed.id).removeClass("feedWithElements").html(feed.id.name);
                });
            }
        });
    });
}

// display unread posts from this feed
function displayFeed(id) {
    display("/reader/render/feed/" + id, {}, function() {
        var feed = getFeed(id);
        $("#feed_" + id).removeClass("feedWithElements").html(feed.name);
        $.each(feeds_information, function(i, category) {
            if (category.name == feed.category) {
                // we found the category, now we look if one of the feed still contain unread feeds
                var unreadFeed = false;
                $.each(category.feeds, function (i, f) {
                    unreadFeed = unreadFeed || $("#feed_" + f.id).hasClass("feedWithElements");
                });
                if (!unreadFeed) {
                    $("#category_" + i).removeClass("categoryWithElements").html(category.name);
                }
            }
        });
    });
}

function display(url, params, callback) {
    params.displayedIds = displayedIds;
    $.getJSON(url, params, function(data) {
        var content = $("#readerContent");
        content.slideUp(function() {
            var result = '';
            displayedIds = [];
            $.each(data, function(id, feedItem) {
                var feed = getFeed(feedItem.id);
                var feedName = feed ? feed.name : '';
                result += '\n<div class="feedContent">'
                        + '\n\t<div class="feedTitle"><a href="' + feed.site_uri + '">' + feedName + '</a></div>';
                $.each(feedItem.posts, function(id, post) {
                    displayedIds.push(post.id);
                    result += '\n\t\t<div class="postHeader">'
                            + '<a id="postExpander_' + post.id + '" href="#" onclick="clickPostExpander(' + post.id + '); return false;">' + (feed.display_content ? '-' : '+' ) + '</a> '
                            + '<a href="' + post.link + '" target="_blank">' + post.title + '</a>'
                            + '<span class="postDate">' + post.published_at + '</span>'
                            + '</div>'
                            + '\n\t\t<div id="post_' + post.id + '" class="postContent' + (feed.display_content ? '' : ' hiddenPost' ) + '">' + post.content + '</div>'
                });
                result += '\n\t</div>';
            });
            result += '<div id="readOk"><a href="#" onclick="postsRead(); return false;">I\'ve read it all!</a></div>';
            content.html(result);
            content.slideDown();
            if (callback != null) {
                callback();
            }
        });
    });
}

function postsRead() {
    $.get("/reader/postsRead", {displayedIds: displayedIds}, function(data) {
        $("#readerContent").slideUp();
    });
}

function clickPostExpander(id) {
    var postExpander = $("#postExpander_" + id);
    if (postExpander.html() == "+") {
        // will expand
        $("#post_" + id).slideDown(function() {
            postExpander.html("–");
        });
    } else {
        // will collapse
        $("#post_" + id).slideUp(function() {
            postExpander.html('+');
        });
    }
}

// get a feed from its id
function getFeed(feedId) {
    var result = null;
    $.each(feeds_information, function(i, category) {
        $.each(category.feeds, function (i, feed) {
            if (feed.id == feedId) {
                result = feed;
            }
        });
    });
    return result;
}