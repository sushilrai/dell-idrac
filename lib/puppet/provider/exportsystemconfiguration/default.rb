provider_path = Pathname.new(__FILE__).parent.parent
require 'rexml/document'

include REXML
require File.join(provider_path, 'idrac')
require File.join(provider_path, 'checklcstatus')
require File.join(provider_path, 'checkjdstatus')
require File.join(provider_path, 'exporttemplatexml')

Puppet::Type.type(:exportsystemconfiguration).provide(:exportsystemconfiguration, :parent => Puppet::Provider::Idrac) do
  desc "Dell idrac provider for export system configuration."
  $count = 0
  $maxcount = 30

  def create
    #Export System Configuration
	  instanceid = exporttemplate 
    for i in 0..30
	    response = checkjobstatus instanceid
      if response  == "Completed"
        Puppet.info "Export System Configuration is completed."
        break
      else
        if response  == "Failed"
          raise "Job Failed."
        else
          Puppet.info "Job is running, wait for 1 minute."
          sleep 60
        end
      end
    end
    if response != "Completed"
      raise "Export System Configuration has not completed."
    end
  end
  
  def exporttemplate
    obj = Puppet::Provider::Exporttemplatexml.new(resource[:dracipaddress],resource[:dracusername],resource[:dracpassword],resource[:configxmlfilename],resource[:nfsipaddress],resource[:nfssharepath])
    instanceid = obj.exporttemplatexml
	  return instanceid
  end

  def checkjobstatus(instanceid)
	  obj = Puppet::Provider::Checkjdstatus.new(resource[:dracipaddress],resource[:dracusername],resource[:dracpassword],instanceid)
    response = obj.checkjdstatus
	  return response
  end
 
  def lcstatus
    obj = Puppet::Provider::Checklcstatus.new(resource[:dracipaddress],resource[:dracusername],resource[:dracpassword])
    response = obj.checklcstatus
	  return response
  end 
  
  def exists?
	  response = lcstatus
    response = response.to_i
    if response == 0
      return false
    else
      #recursive call  method exists till lcstatus =0
      while $count < $maxcount  do
        Puppet.info "LC status busy, wait for 1 minute"
        sleep 5
        $count +=1
        exists?
      end
      raise Puppet::Error, "Life cycle controller is busy"
      return true
    end
  end
end

