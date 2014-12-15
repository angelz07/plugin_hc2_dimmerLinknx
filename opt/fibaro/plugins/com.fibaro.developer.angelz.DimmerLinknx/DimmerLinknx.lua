-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Name: DimmerLinknx
-- Type: Plugin
-- Version:	1.0.0 beta
-- Release date: 20-10-2014
-- Author: Fabrice Bernardi
-------------------------------------------------------------------------------------------

--! includes
require('common.device')
require('net.HTTPClient')

class 'DimmerLinknx' (Device)
local ip_hc2
local globalConfigured

--@param id: Id of the device.
function DimmerLinknx:__init(id)
    Device.__init(self, id)
    self.http = net.HTTPClient({ timeout = 10000 })
    self:test_prop()
end


function DimmerLinknx:test_prop()
  local configured = false

  local ip_nodejs = self.properties.ip_nodejs
  local port_nodejs = self.properties.port_nodejs
  local id_linknx_cmd = self.properties.id_linknx_cmd
  local id_linknx_status = self.properties.id_linknx_status

  if(ip_nodejs == '') then
    configured = false
  else
    configured = true
  end
  
  if(port_nodejs == '') then
    configured = false
  else
    configured = true
  end

  if(id_linknx_cmd == '') then
    configured = false
  else
    configured = true
  end

  if(id_linknx_status == '') then
    configured = false
  else
    configured = true
  end

  
  if(tostring(configured) == 'true') then
    self:updateProperty('configured',true)
    globalConfigured = true;
    self:updateProperty('ui.debug.caption', '')
    self:get_ip_hc2()  
  else
    self:updateProperty('configured',false)
    self:updateProperty('ui.debug.caption', 'Paramètres de configuration Manquant')
    globalConfigured = false
   -- self.test_prop(id)
  end
  --self:init_temp_piece()
end


function DimmerLinknx:get_ip_hc2()
    local url = 'http://127.0.0.1:11111/api/settings/network'
    self.headers = {
            }
     self.http:request(url, {
        options = {
            method = 'GET',
            headers = self.headers
        },
        success = function(response) 
           if (response.status == 200 and response.data) then
              local result_json = json.decode(response.data)
                if result_json.ip then
                --    self:updateProperty('ui.debug.caption', 'response mode= ' .. tostring(result_json.ip))
                    ip_hc2 = tostring(result_json.ip)
                    
                 self:init_state()
              end
            end
        end,
        error = function(err) print(err) end
    })
end



--! [public] Restart action
function DimmerLinknx:restartPlugin()
  plugin.restart()
end

function DimmerLinknx:setValue(arg)
  if (globalConfigured == true) then
    local valeur_255 = (tonumber(arg) / 100) * 255
    local valeur_255_round =  math.ceil(tonumber(valeur_255) )
    if(valeur_255_round > 255) then
      valeur_255_round = 255
    end

    if(valeur_255_round < 0) then
      valeur_255_round = 0
    end
    self:set_val_knx(valeur_255_round)
    self:updateProperty('ui.debug.caption',tostring(valeur_255))
  end
end

function DimmerLinknx:turnOff()
  self:set_val_knx(0)
end

function DimmerLinknx:turnOn()
  self:set_val_knx(255)
end

function DimmerLinknx:update_slide_tuile(arg)
  local valeur_100 = (tonumber(arg) / 255) * 100
  local valeur_100_round =  math.ceil(tonumber(valeur_100) )
  self:updateProperty('value',valeur_100_round)
end

function DimmerLinknx:set_val_knx(valeur)
  if (globalConfigured == true) then
    local ip_nodejs = self.properties.ip_nodejs
    local port_nodejs = self.properties.port_nodejs
    local id_linknx_cmd = self.properties.id_linknx_cmd
    local id_linknx_status = self.properties.id_linknx_status
    local url = 'http://' .. ip_nodejs .. ':' .. port_nodejs .. '/send_cmd?demande=linknx&id=' .. id_linknx_cmd .. '&value=' .. valeur
    --local url2 = 'http://' .. ip_nodejs .. ':' .. port_nodejs .. '/send_cmd?demande=linknx&id=' .. id_linknx_status .. '&value=' .. valeur
    self:httpRequest(url)
    self:update_slide(valeur)
    self:update_slide_tuile(valeur)

    local valeur_100 = (tonumber(valeur) / 255) * 100
    local valeur_100_round =  math.ceil(tonumber(valeur_100) )
    --self:updateProperty('ui.debug.caption',' valeur_100_round = ' .. tostring(valeur_100_round) )
    self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.DimmerLinknx/img/'  .. tostring(valeur_100_round) .. '.png')
  end
end

--! Prepares HTTPClient object to do http request on freebox
--@param url The url
function DimmerLinknx:httpRequest(url)
  --self:updateProperty('ui.debug.caption',url)
  self.headers = {
            }
   self.http:request(url, {
        options = {
            method = 'GET',
            headers = self.headers
        },
        success = function(data) print(data.status) end,
        error = function(err) print(err) end
    })
end

function DimmerLinknx:update_slide(valeur)
    self:updateProperty('ui.slide_dimmer.value',tonumber(valeur))
end

function DimmerLinknx:receive_data(id,value)
  if (globalConfigured == true) then
    value = tostring(value)
    id = tostring(id)
    local id_linknx_cmd = self.properties.id_linknx_cmd
    local id_linknx_status = self.properties.id_linknx_status
    if (tostring(id_linknx_status) == id) then
        self:update_slide(value)
        self:set_val_knx(value)
    elseif (id_lid_linknx_statusinknx == id) then
        self:update_slide(value)
        self:set_val_knx(value)    
    end
  end
end


function DimmerLinknx:init_state()
  if (globalConfigured == true) then
    local ip_nodejs = self.properties.ip_nodejs
    local port_nodejs = self.properties.port_nodejs
    local id_linknx_cmd = self.properties.id_linknx_cmd
    local id_linknx_status = self.properties.id_linknx_status
    local url = 'http://' .. ip_nodejs .. ':' .. port_nodejs .. '/etat_linknx_1_obj?id_linknx=' .. id_linknx_status 
   -- self:updateProperty('ui.debug.caption',tostring(url))
    self.headers = {
              }
     self.http:request(url, {
          options = {
              method = 'GET',
              headers = self.headers
          },
          success = function(response) 

             if (response.status == 200 and response.data) then
                local result_json = json.decode(response.data)
             --   self:updateProperty('ui.debug.caption',tostring(response.data))
                if result_json.objects then
                  if result_json.objects[1] then
                        local objet = result_json.objects[1]
                        local objet_json = objet
                        local id  = objet_json.id
                        local value  = objet_json.value
                        if (tostring(id_linknx_status) == tostring(id)) then
                          self:update_slide(value)
                          self:update_slide_tuile(value)

                          self:updateProperty('ui.icone.source','http://' .. ip_hc2 .. '/plugins/com.fibaro.developer.angelz.DimmerLinknx/img/'  .. tostring(value) .. '.png')
                        end
                  end
                end
              end
          end,
          error = function(err) self:updateProperty('ui.debug.caption', 'Err : ' .. err) end
      })
  end
end

