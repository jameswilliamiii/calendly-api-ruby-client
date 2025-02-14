# frozen_string_literal: true

require 'calendly/client'
require 'calendly/models/model_utils'
require 'calendly/models/event_type'
require 'calendly/models/guest'
require 'calendly/models/invitees_counter'
require 'calendly/models/location'

module Calendly
  # Calendly's event model.
  # A meeting that has been scheduled.
  class Event
    include ModelUtils
    UUID_RE = %r{\A#{Client::API_HOST}/scheduled_events/(\S+)\z}.freeze
    TIME_FIELDS = %i[start_time end_time created_at updated_at].freeze
    ASSOCIATION = {
      event_type: EventType,
      event_guests: Guest,
      invitees_counter: InviteesCounter,
      location: Location
    }.freeze

    # @return [String]
    # unique id of the Event object.
    attr_accessor :uuid

    # @return [String]
    # Canonical resource reference.
    attr_accessor :uri

    # @return [String]
    # Name of the event.
    attr_accessor :name

    # @return [String]
    # Whether the event is active or canceled.
    attr_accessor :status

    # @return [Time]
    # Moment when event is (or was) scheduled to begin.
    attr_accessor :start_time

    # @return [Time]
    # Moment when event is (or was) scheduled to end.
    attr_accessor :end_time

    # @return [Time]
    # Moment when user record was first created.
    attr_accessor :created_at

    # @return [Time]
    # Moment when user record was last updated.
    attr_accessor :updated_at

    # @return [EventType]
    # Reference to Event Type associated with this event.
    attr_accessor :event_type

    # @return [Calendly::Location]
    # location in this event.
    attr_accessor :location

    # @return [InviteesCounter]
    # invitees counter.
    attr_accessor :invitees_counter

    # @return [Array<User>]
    # Event membership list.
    attr_accessor :event_memberships

    # @return [Array<Guest>]
    # Additional people added to an event by an invitee.
    attr_accessor :event_guests

    #
    # Get Scheduled Event associated with self.
    #
    # @return [Calendly::Event]
    # @raise [Calendly::Error] if the uuid is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.1.0
    def fetch
      client.scheduled_event uuid
    end

    #
    # Returns all Event Invitees associated with self.
    #
    # @param [Hash] options the optional request parameters. Optional.
    # @option options [Integer] :count Number of rows to return.
    # @option options [String] :email Filter by email.
    # @option options [String] :page_token
    # Pass this to get the next portion of collection.
    # @option opts [String] :sort Order results by the specified field and directin.
    # Accepts comma-separated list of {field}:{direction} values.
    # @option opts [String] :status Whether the scheduled event is active or canceled.
    # @return [Array<Calendly::Invitee>]
    # @raise [Calendly::Error] if the uuid is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.1.0
    def invitees(options: nil)
      return @cached_invitees if defined?(@cached_invitees) && @cached_invitees

      request_proc = proc { |opts| client.event_invitees uuid, options: opts }
      @cached_invitees = auto_pagination request_proc, options
    end

    # @since 0.2.0
    def invitees!(options: nil)
      @cached_invitees = nil
      invitees options: options
    end

  private

    def after_set_attributes(attrs)
      super attrs
      if event_memberships.is_a? Array # rubocop:disable Style/GuardClause
        @event_memberships = event_memberships.map do |params|
          uri = params[:user]
          User.new({uri: uri}, @client)
        end
      end
    end
  end
end
