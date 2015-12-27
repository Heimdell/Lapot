
require 'gtk3'

class App

  def self.create &block
    @@framestack      = [Gtk::Window.new]
    @@registration_on = true

    flow { self.instance_eval &block }

    window = @@framestack.first
    window.show_all
    Gtk.main
  end

  def self.sequence direction
    start_collecting direction
    yield
    it = stop_collecting
    register it
    it
  end

  def self.stack
    sequence :vertical { yield }
  end

  def self.flow
    sequence :horizontal { yield }
  end

  def self.start_collecting align
    vbox    = Gtk::Box.new align, 0
    e_space = Gtk::Alignment.new 0, 0, 0, 0
    vbox.pack_start e_space, expand: true
    @@framestack += [vbox]
  end

  def self.stop_collecting
    @@framestack.pop
  end

  def self.register thing
    @@framestack.last.add thing if @@registration_on
  end

  def self.construct_customly
    @@registration_on = false
    result = yield
    @@registration_on = true
    result
  end

  def self.button name
    it = Gtk::Button.new label: name
    register it

    it.signal_connect "clicked" { yield } if block_given?
    it
  end

  def self.line_input
    it = Gtk::Entry.new
    register it

    if block_given?
      it.signal_connect "key-release-event" do |sender, event|
        yield sender, event
      end
    end
    it
  end

  def self.date
    it = Gtk::Calendar.new
    register it
    it
  end

  def self.change kwargs
    thing = yield
    kwargs.each do |k, v|
      thing.send "set_#{k}", *v
    end
    thing
  end

  def self.label name
    it = Gtk::Label.new name
    register it
    it
  end

  def self.form *things
    it = change column_spacing: 5, row_spacing: 5 do
      Gtk::Grid.new
    end

    construct_customly do
      things.each.with_index do |(name, type), i|
        k = label "#{name}"
        v = 
          case type
          when :plain
            line_input
          when :date
            date
          end

        it.attach k, 0, i, 1, 1
        it.attach v, 1, i, 1, 1
      end
    end
    register it
    it
  end

  def self.dialog wat
    it = Gtk::MessageDialog.new({
      parent: @@framestack.first,
      flags:    0,
      type:    :info,
      buttons: :ok_cancel,
      message:  wat
    })

    resp = it.run
    it.destroy
    yield resp
  end
end

#### 8< #######################################################################

App.create do
  change margin: 10 do
    stack do
      form [:id,   :plain],
           [:date, :date],
           [:sum,  :plain]

      flow do
        button "useless"

        change label: "NO" do
          it = button "YES" do
            dialog "WAT" do |resp|
              it.label = "#{resp.name}"
            end
          end
        end
      end
    end
  end
end
