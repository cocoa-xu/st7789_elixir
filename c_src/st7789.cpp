#include <erl_nif.h>
#include <memory>
#include <vector>
#include <tuple>
#include <string>
#include "nif_utils.hpp"

#ifdef __GNUC__
#  pragma GCC diagnostic ignored "-Wunused-parameter"
#  pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#  pragma GCC diagnostic ignored "-Wunused-variable"
#  pragma GCC diagnostic ignored "-Wunused-function"
#endif

static ERL_NIF_TERM to_565(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 3) {
        return erlang::nif::error(env, "expecting 3 arguments: image_data, channel_order_source, channel_order_target");
    }

    std::string channel_order_source, channel_order_target;
    erlang::nif::get_atom(env, argv[1], channel_order_source);
    erlang::nif::get_atom(env, argv[2], channel_order_target);
    ErlNifBinary binary;
    if (enif_inspect_binary(env, argv[0], &binary)) {
        if (binary.size % 24 == 0) {
            size_t bytes_rgb565 = binary.size / 24 * 16;
            size_t num_pixels = binary.size / 3;
            ErlNifBinary result;
            if (!enif_alloc_binary(bytes_rgb565, &result)) {
                return erlang::nif::error(env, "enif_alloc_binary failed");
            }

            uint16_t * data = (uint16_t *)result.data;
            const unsigned char * binary_data = binary.data;
            size_t r_offset = 0, b_offset = 2;
            if (channel_order_source == "bgr") {
                r_offset = 2;
                b_offset = 0;
            }
            bool target_bgr = (channel_order_target == "bgr");
            if (target_bgr) {
#pragma omp parallel for
                for (size_t i = 0; i < num_pixels; ++i) {
                    size_t index = i * 3;
                    uint16_t r = binary_data[index + r_offset];
                    uint16_t g = binary_data[index + 1];
                    uint16_t b = binary_data[index + b_offset];
                    uint16_t format565 = 0;
                    format565 = ((b & 0xF8) << 8) | ((g & 0xFC) << 3) | ((r & 0xF8) >> 3);
                    data[i] = (format565>>8) | (format565<<8);
                }
            } else {
#pragma omp parallel for
                for (size_t i = 0; i < num_pixels; ++i) {
                    size_t index = i * 3;
                    uint16_t r = binary_data[index + r_offset];
                    uint16_t g = binary_data[index + 1];
                    uint16_t b = binary_data[index + b_offset];
                    uint16_t format565 = 0;
                    format565 = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3);
                    data[i] = (format565>>8) | (format565<<8);
                }
            }

            return enif_make_binary(env, &result);
        }
        return erlang::nif::error(env, "malformed BGR888/RGB888 binary data");
    } else {
        return erlang::nif::error(env, "expecting bitstring");
    }
}

static int on_load(ErlNifEnv* env, void**, ERL_NIF_TERM)
{
    return 0;
}

static int on_reload(ErlNifEnv*, void**, ERL_NIF_TERM)
{
    return 0;
}

static int on_upgrade(ErlNifEnv*, void**, void**, ERL_NIF_TERM)
{
    return 0;
}

#define F(NAME, ARITY) {#NAME, ARITY, NAME, 0}

static ErlNifFunc nif_functions[] = {
    F(to_565, 3)
};

ERL_NIF_INIT(st7789_nif, nif_functions, on_load, on_reload, on_upgrade, NULL);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#endif
