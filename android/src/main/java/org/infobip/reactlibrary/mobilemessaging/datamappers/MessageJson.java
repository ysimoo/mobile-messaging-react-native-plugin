package org.infobip.reactlibrary.mobilemessaging.datamappers;

import android.os.Bundle;
import androidx.annotation.NonNull;
import android.util.Log;

import org.infobip.reactlibrary.mobilemessaging.Utils;

import org.infobip.mobile.messaging.Message;
import org.infobip.mobile.messaging.geo.Area;
import org.infobip.mobile.messaging.geo.Geo;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class MessageJson {
    /**
     * Creates new json object based on message bundle
     *
     * @param bundle message bundle
     * @return message object in json format
     */
    public static JSONObject bundleToJSON(Bundle bundle) {
        Message message = Message.createFrom(bundle);
        if (message == null) {
            return null;
        }

        return toJSON(message);
    }

    /**
     * Creates json from a message object
     *
     * @param message message object
     * @return message json
     */
    public static JSONObject toJSON(Message message) {
        try {
            return new JSONObject()
                    .putOpt("messageId", message.getMessageId())
                    .putOpt("title", message.getTitle())
                    .putOpt("body", message.getBody())
                    .putOpt("sound", message.getSound())
                    .putOpt("vibrate", message.isVibrate())
                    .putOpt("icon", message.getIcon())
                    .putOpt("silent", message.isSilent())
                    .putOpt("category", message.getCategory())
                    .putOpt("from", message.getFrom())
                    .putOpt("receivedTimestamp", message.getReceivedTimestamp())
                    .putOpt("customPayload", message.getCustomPayload())
                    .putOpt("contentUrl", message.getContentUrl())
                    .putOpt("seen", message.getSeenTimestamp() != 0)
                    .putOpt("seenDate", message.getSeenTimestamp())
                    .putOpt("geo", hasGeo(message))
                    .putOpt("chat", message.isChatMessage());
        } catch (JSONException e) {
            Log.w(Utils.TAG, "Cannot convert message to JSON: " + e.getMessage());
            Log.d(Utils.TAG, Log.getStackTraceString(e));
            return null;
        }
    }

    private static boolean hasGeo(Message message) {
        if (message == null || message.getInternalData() == null) {
            return false;
        }

        try {
            JSONObject geo = new JSONObject(message.getInternalData());
            return geo.getJSONArray("geo") != null && geo.getJSONArray("geo").length() > 0;
        } catch (JSONException e) {
            return false;
        }
    }

    /**
     * Creates array of json objects from list of messages
     *
     * @param messages list of messages
     * @return array of jsons representing messages
     */
    public static JSONArray toJSONArray(@NonNull Message messages[]) {
        JSONArray array = new JSONArray();
        for (Message message : messages) {
            JSONObject json = toJSON(message);
            if (json == null) {
                continue;
            }
            array.put(json);
        }
        return array;
    }

    /**
     * Creates new messages from json object
     *
     * @param json json object
     * @return new {@link Message} object.
     */
    private static Message fromJSON(JSONObject json) {
        if (json == null) {
            return null;
        }

        Message message = new Message();
        message.setMessageId(json.optString("messageId", null));
        message.setTitle(json.optString("title", null));
        message.setBody(json.optString("body", null));
        message.setSound(json.optString("sound", null));
        message.setVibrate(json.optBoolean("vibrate", true));
        message.setIcon(json.optString("icon", null));
        message.setSilent(json.optBoolean("silent", false));
        message.setCategory(json.optString("category", null));
        message.setFrom(json.optString("from", null));
        message.setReceivedTimestamp(json.optLong("receivedTimestamp", 0));
        message.setCustomPayload(json.optJSONObject("customPayload"));
        return message;
    }

    /**
     * Geo mapper
     *
     * @param bundle where to read geo objects from
     * @return list of json objects representing geo objects
     */
    @NonNull
    public static List<JSONObject> geosFromBundle(Bundle bundle) {
        Geo geo = Geo.createFrom(bundle);
        JSONObject message = bundleToJSON(bundle);
        if (geo == null || geo.getAreasList() == null || geo.getAreasList().isEmpty() || message == null) {
            return new ArrayList<JSONObject>();
        }

        List<JSONObject> geos = new ArrayList<JSONObject>();
        for (final Area area : geo.getAreasList()) {
            try {
                geos.add(new JSONObject()
                        .put("area", new JSONObject()
                                .put("id", area.getId())
                                .put("center", new JSONObject()
                                        .put("lat", area.getLatitude())
                                        .put("lon", area.getLongitude()))
                                .put("radius", area.getRadius())
                                .put("title", area.getTitle()))
                );
            } catch (JSONException e) {
                Log.w(Utils.TAG, "Cannot convert geo to JSON: " + e.getMessage());
                Log.d(Utils.TAG, Log.getStackTraceString(e));
            }
        }

        return geos;
    }

    @NonNull
    public static List<Message> resolveMessages(JSONArray args) throws JSONException {
        if (args == null || args.length() < 1 || args.getString(0) == null) {
            throw new IllegalArgumentException("Cannot resolve messages from arguments");
        }

        List<Message> messages = new ArrayList<Message>(args.length());
        for (int i = 0; i < args.length(); i++) {
            Message m = fromJSON(args.optJSONObject(i));
            if (m == null) {
                continue;
            }

            messages.add(m);
        }
        return messages;
    }
}
