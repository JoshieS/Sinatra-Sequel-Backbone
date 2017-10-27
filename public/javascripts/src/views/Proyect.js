const CreateCommentProyectSubView = require('./proyect_subviews/CreateCommentProyectSubView')
const CommentsCollectionSubView = require('./proyect_subviews/CommentsCollectionSubView')
const toastError = require('../helpers/toastConnectionError')
const messages = require('../../../../tmp/messages.json')
const template = require('../../../../views/application_views/proyect.erb')

module.exports = Mn.View.extend({
  template: template,
  regions: {
    commentsRegion: '#comments-region',
    createCommentRegion: '#createComment-region',
    editModalRegion: '#modalEdit-region',
    snippetsRegion: '#snippets-region'
  },
  ui: {
    likeButton: '#ui-like-action',
    buttonWriteComment: '#ui-button-toggleForm',
  },
  events: {
    'click @ui.likeButton': 'toggleLike',
    'click @ui.buttonWriteComment': 'toggleRenderFormComment'    
  },
  modelEvents: {
    'destroy': 'redirectToProfile',
    'invalid': function(model, error, options) {
      this.showToastInvalid(model, error, options);
    }
  },
  childViewEvents: {
    'modalIsClose': 'destroyModelView',
    'commentCreated': 'destroyCommentView'
  },
  initialize: function () {
    this.proyect_id = this.model.id;
    this.current_user = this.getOption('application').current_user;
  },
  templateContext: function() {
    var that = this;
    return {
      user_authenticated_is_the_owner: function(id_user) {
        return that.current_user.is_authenticated() && that.current_user.get('id') == id_user
      }
    }
  },
  onRender: function () {
    this.renderLikes();
    this.renderSnippets();
    this.renderComments();
  },
  destroyCommentView: function () {
    this.getUI('buttonWriteComment')
      .addClass('right')
      .removeClass('left btn-warning')
      .html('<i class="fa fa-pencil"></i> Write a comment');

    var regionView = this.getChildView('createCommentRegion');
    regionView.destroy();
  },
  renderComments: function () {
    this.showChildView('commentsRegion', new CommentsCollectionSubView({
      idParent: this.proyect_id,
      parent: this
    }));
  },
  renderSnippets: function () {
    return false;
  },
  renderLikes: function () {
    var button = this.getUI('likeButton');
    $.when(this.model.getLikesCount()).then(function(data) {
      button.attr('data-likes', data.likes);
    });
  },
  redirectToProfile: function () {
    this.getOption('application').BasicRouter.navigate('user/' + this.current_user.id , {trigger: true});
    $.toast({
      heading: 'Success',
      text: messages['proyect'].delete,
      icon: 'success',
      showHideTransition: 'slide'
    });
  },
  toggleLike: function () {
    var button = this.getUI('likeButton'),
        id_user = this.current_user.get('id');

    if (id_user) {
      $.when(this.model.createOrDeleteLike(id_user)).then(function(data) {
        button.attr('data-likes', data.likes);
      });
    } else {
      $.toast({
        heading: 'Ups...',
        text: messages['proyect'].like-without-auth,
        icon: 'info',
        showHideTransition: 'slide'
      });
    }
  },
  toggleRenderFormComment: function () {
    var regionView = this.getChildView('createCommentRegion');

    if (regionView) {

      this.getUI('buttonWriteComment')
        .addClass('right')
        .removeClass('left btn-warning')
        .html('<i class="fa fa-pencil"></i> Write a comment');

      regionView.destroy();

    } else {

      this.getUI('buttonWriteComment')
        .addClass('left btn-warning')
        .removeClass('right')
        .html('<i class="fa fa-window-close"></i> Cancel');

      this.showChildView('createCommentRegion',
        new CreateCommentProyectSubView({
          proyect_id: this.model.get('id'),
          collection_comment: this.getChildView('commentsRegion').collection,
          current_user: this.current_user
        })
      );

    }
  },
  showToastInvalid: function (model, error, options) {
    $.toast({
      heading: 'Error!',
      text: error,
      icon: 'error',
      showHideTransition: 'slide'
    });
  }
});