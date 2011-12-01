# stolen from pusher-server - watch out for keeping that version in
# sync with this one
class Version
  include Comparable

  attr_accessor :version, :mmp_version

  #
  # Takes a version string and initialises it as a Version object
  #
  #   Valid Version strings are:
  #     - 0.0
  #     - 0.0.0
  #     - 0.0.0-pre
  #
  def initialize(str)
    @version = str
    @mmp_version = str.split('-', 2)[0].split('.', 3).map do |v|
      v.to_i
    end
  end

  def to_s
    @version
  end

  def <=> other
    # Cast strings to be a proper Version object,
    # makes code a lot cleaner when comparing versions.
    if other.is_a?(String)
      other = Version.new(other)
    end

    mmp_version <=> other.mmp_version
  end
end
