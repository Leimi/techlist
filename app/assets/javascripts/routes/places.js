App.PlacesRoute = Ember.Route.extend({
  model: function() { return this.store.find('place') }
})
