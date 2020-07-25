using CCDReduction: getdata,
                    get_bitpix,
                    get_default_header

function test_header(ccd1::CCDData, ccd2::CCDData)
    header1 = ccd1.hdr
    header2 = ccd2.hdr
    @test keys(header1) == keys(header2)
    for (k1, k2) in zip(keys(header1), keys(header2))
        @test header1[k1] == header2[k2]
    end
end

@testset "bias subtraction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    hdu_bias_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])
    array_bias_frame = getdata(M6707HH[1])

    # non-mutating version
    # testing CCDData CCDData case
    processed_frame = subtract_bias(hdu_frame, hdu_bias_frame)
    @test processed_frame isa CCDData
    @test processed_frame.data == zeros(1059, 1059)
    test_header(processed_frame, hdu_frame)

    ## testing Array CCDData case
    processed_frame = subtract_bias(array_frame, hdu_bias_frame)
    @test processed_frame isa Array
    @test processed_frame == zeros(1059, 1059)

    # testing CCDData case
    processed_frame = subtract_bias(hdu_frame, array_bias_frame)
    @test processed_frame isa CCDData
    @test processed_frame.data == zeros(1059, 1059)
    test_header(processed_frame, hdu_frame)

    # testing mutating version
    # testing CCDData CCDData case
    hdu_frame = CCDData(M6707HH[1])
    subtract_bias!(hdu_frame, hdu_bias_frame)
    @test hdu_frame isa CCDData
    @test hdu_frame.data == zeros(1059, 1059)

    # testing CCDData Array case
    hdu_frame = CCDData(M6707HH[1])
    subtract_bias!(hdu_frame, array_bias_frame)
    @test hdu_frame isa CCDData
    @test hdu_frame.data == zeros(1059, 1059)

    # testing Array CCDData case
    array_frame = getdata(M6707HH[1])
    subtract_bias!(array_frame, hdu_bias_frame)
    @test array_frame isa Array
    @test array_frame == zeros(1059, 1059)

    # testing error in mutating version
    hdu_frame = CCDData(fill(2, 5, 5))
    hdu_bias = CCDData(fill(2.5, 5, 5))
    @test_throws InexactError subtract_bias!(hdu_frame, hdu_bias)
end

@testset "overscan subtraction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])

    # testing non-mutating version
    processed_frame = subtract_overscan(hdu_frame, (:, 1050:1059))
    @test processed_frame isa CCDData
    @test processed_frame.data == subtract_overscan(array_frame, (:, 1050:1059))
    test_header(processed_frame, hdu_frame)

    processed_frame = subtract_overscan(hdu_frame, "1050:1059, 1:1059")
    processed_frame isa CCDData
    @test processed_frame.data == subtract_overscan(array_frame, (:, 1050:1059))

    # testing mutating version
    hdu_frame = CCDData(M6707HH[1])
    subtract_overscan!(hdu_frame, (:, 1050:1059))
    @test hdu_frame.data == subtract_overscan(array_frame, (:, 1050:1059))

    hdu_frame = CCDData(M6707HH[1])
    subtract_overscan!(hdu_frame, "1050:1059, 1:1059")
    @test hdu_frame.data == subtract_overscan(array_frame, (:, 1050:1059))
end

@testset "flat correction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    hdu_flat_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])
    array_flat_frame = getdata(M6707HH[1])
    mean_flat_frame = mean(array_flat_frame)

    # testing non mutating version
    # testing CCDData CCDData case
    processed_frame = flat_correct(hdu_frame, hdu_flat_frame)
    @test processed_frame isa CCDData
    test_header(processed_frame, hdu_frame)
    @test processed_frame.data ≈ fill(mean_flat_frame, 1059, 1059)

    # testing CCDData Array case
    processed_frame = flat_correct(hdu_frame, array_flat_frame; norm_value = 1)
    @test processed_frame isa CCDData
    @test processed_frame.data ≈ ones(1059, 1059)

    # testing Array CCDData case
    processed_frame = flat_correct(array_frame, hdu_flat_frame; norm_value = 1)
    @test processed_frame isa Array
    @test processed_frame ≈ ones(1059, 1059)

    # testing type mutation in non mutating version
    hdu_frame = CCDData(fill(1, 5, 5))
    bias_frame = CCDData(fill(2.0, 5, 5))
    processed_frame = flat_correct(hdu_frame, bias_frame; norm_value = 1)
    @test processed_frame isa CCDData
    @test processed_frame.data ≈ fill(0.5, 5, 5)

    # testing mutating version
    hdu_frame = CCDData(ones(5, 5))
    flat_correct!(hdu_frame, fill(2.0, 5, 5); norm_value = 1)
    @test hdu_frame.data ≈ fill(0.5, 5, 5)

    # testing type error in mutating version
    frame = CCDData(fill(1, 5 ,5))
    @test_throws InexactError flat_correct!(frame, fill(2.0, 5, 5); norm_value = 1)
end

@testset "trim(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    array_frame = M6707HH[1] |> getdata

    # testing trum
    processed_frame = trim(hdu_frame, (:, 1050:1059))
    @test processed_frame isa CCDData
    @test processed_frame.data == trim(array_frame, (:, 1050:1059))

    processed_frame = trim(hdu_frame, "1:1059, 1050:1059")
    test_header(processed_frame, hdu_frame)
    @test processed_frame isa CCDData
    @test processed_frame.data isa Array
    @test processed_frame.data == trim(array_frame, (1050:1059, :))

    # testing trimview
    processed_frame = trimview(hdu_frame, (:, 1050:1059))
    @test processed_frame isa CCDData
    @test processed_frame.data isa SubArray
    processed_frame.data[3] = 16
    @test hdu_frame.data[3] == 16 # modifying processed_frame modifies hdu_frame
end

@testset "cropping(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])

    # testing crop
    processed_frame = crop(hdu_frame, (:, 5))
    @test processed_frame isa CCDData
    @test processed_frame.data isa Array
    @test processed_frame.data == crop(array_frame, (:, 5))

    @test_logs (:warn, "dimension 1 changed from 348 to 349") (:warn, "dimension 2 changed from 226 to 227") processed_frame = crop(hdu_frame, (348, 226))
    @test processed_frame isa CCDData
    @test processed_frame.data isa Array
    @test_logs (:warn, "dimension 1 changed from 348 to 349") (:warn, "dimension 2 changed from 226 to 227") @test processed_frame.data == crop(array_frame, (348, 226))

    processed_frame = crop(hdu_frame, (1000, 5); force_equal = false)
    @test processed_frame isa CCDData
    @test processed_frame.data isa Array
    @test processed_frame.data == crop(array_frame, (1000, 5); force_equal = false)

    # testing trimview
    processed_frame = cropview(hdu_frame, (:, :))
    @test processed_frame isa CCDData
    @test processed_frame.data isa SubArray
    processed_frame.data[5] = 1
    @test hdu_frame[5] == 1 # modifying processed_frame modifies hdu_frame
end


# @testset "combine(FITS)" begin
#     # setting initial data
#     frame = M6707HH[1] |> getdata
#     vector_hdu = [M6707HH[1] for i in 1:3]
#     vector_frames = [frame for i in 1:3]
#     vector_frames_dir = [test_file_path_M6707HH for i in 1:3]
#
#     # testing the vector version
#     @test combine(vector_hdu) == combine(vector_frames)
#     @test combine(vector_frames_dir) == combine(vector_frames)
#
#     # testing the varargs version
#     @test combine(M6707HH[1], M6707HH[1], M6707HH[1]) == combine(vector_frames)
#     @test combine(test_file_path_M6707HH, test_file_path_M6707HH, test_file_path_M6707HH) == combine(vector_frames)
#
#     # testing with kwargs
#     @test combine(vector_frames_dir; hdu = 1, method = sum) == combine(vector_frames_dir; hdu = (1, 1, 1), method = sum)
#     @test combine(test_file_path_M6707HH, test_file_path_M6707HH; hdu = 1) == combine(test_file_path_M6707HH, test_file_path_M6707HH)
# end


@testset "dark subtraction(FITS)" begin
    # setting initial data
    hdu_frame = CCDData(M6707HH[1])
    hdu_bias_frame = CCDData(M6707HH[1])
    array_frame = getdata(M6707HH[1])
    array_bias_frame = getdata(M6707HH[1])

    # testing non-mutating version
    # testing CCDData CCDData case
    processed_frame = subtract_dark(hdu_frame, hdu_bias_frame; dark_exposure = 0.5)
    @test processed_frame isa CCDData
    test_header(processed_frame, hdu_frame)
    @test processed_frame == (-1) .* array_frame

    # testing CCDData Array case
    processed_frame = subtract_dark(hdu_frame, array_bias_frame; dark_exposure = 2, data_exposure = 2)
    @test processed_frame isa CCDData
    @test processed_frame.data == zeros(1059, 1059)

    # testing Array CCDData
    processed_frame = subtract_dark(array_frame, hdu_bias_frame; dark_exposure = 2, data_exposure = 2)
    @test processed_frame isa Array
    @test processed_frame == zeros(1059, 1059)

    # testing mutating version
    hdu_frame = CCDData(M6707HH[1])
    subtract_dark!(hdu_frame, hdu_bias_frame; dark_exposure = 2, data_exposure = 2)
    @test hdu_frame.data == zeros(1059, 1059)
end

@testset "helper(FITS)" begin
    # testing getdata
    hdu = M6707HH[1]
    data = read(hdu)'
    @test data == getdata(hdu)

    # testing get_bitpix
    @test get_bitpix(UInt8) == 8
    @test get_bitpix(Int16) == 16
    @test get_bitpix(Int32) == 32
    @test get_bitpix(Int64) == 64
    @test get_bitpix(Float32) == -32
    @test get_bitpix(Float64) == -64

    # testing get_default_header
    data = fill(Int16(2), 5, 6, 2)
    hdr = get_default_header(data)
    @test hdr isa FITSHeader
    @test hdr["SIMPLE"] == "T"
    @test hdr["BITPIX"] == 16
    @test hdr["NAXIS"] == 3
    @test hdr["NAXIS1"] == 2
    @test hdr["NAXIS2"] == 6
    @test hdr["NAXIS3"] == 5
    @test hdr["EXTEND"] == "T"
end
